#!/bin/bash

unameOut="$(uname -s)"
case "${unameOut}" in
    Linux*)     MACHINE_OS=Linux;;
    Darwin*)    MACHINE_OS=Mac;;
    CYGWIN*)    MACHINE_OS=Windows;;
    MINGW*)     MACHINE_OS=Windows;;
    *)          MACHINE_OS="UNKNOWN:${unameOut}"
esac

RUNNING_PATH=$(pwd)


# Uncomment if you want to check only commited code
STAGED_GO_FILES=$(git diff --cached --name-only | grep ".go$")
# STAGED_GO_FILES=$(git diff-index --check --cached HEAD -- | grep ".go$")
# Uncomment if you want to check the entire code
# STAGED_GO_FILES=$(find . -iname "*.go")

# Uncomment this if you want to check changed code (without git commit)
# STAGED_GO_FILES=$(git diff --name-only | grep ".go$")

# DO NOT USE THIS FOR DEV
# STAGED_GO_FILES=$(find . -iname "*_test.go")

if [[ "$STAGED_GO_FILES" = "" ]]; then
    exit 0
fi

GOLINT=$GOPATH/bin/golint
GOLANGCILINT=$GOPATH/bin/golangci-lint
GOIMPORTS=$GOPATH/bin/goimports
GOCYCLO=$GOPATH/bin/gocyclo
GOCRITIC=$GOPATH/src/github.com/go-critic/go-critic/gocritic

# Check for golint
if [[ ! -x "$GOLINT" ]]; then
    printf ">> \033[31mPlease install golint\033[0m (go get -u golang.org/x/lint/golint)"
    exit 1
fi

# Check for goimports
if [[ ! -x "$GOIMPORTS" ]]; then
    printf "\t\033[31mPlease install goimports\033[0m (go get golang.org/x/tools/cmd/goimports)"
    exit 1
fi

# Check for gocyclo
if [[ ! -x "$GOCYCLO" ]]; then
    printf "\t\033[31mPlease install gocyclo\033[0m (go get -v github.com/fzipp/gocyclo/...)"
    exit 1
fi

# Check for gocritic
# if [[ ! -x "$GOCRITIC" ]] && [[ $MACHINE_OS != "Windows" ]]; then
if [[ ! -x "$GOCRITIC" ]]; then
    printf "\t\033[31mPlease install go-critic\033[0m (go get -v github.com/go-lintpack/lintpack/... && go get -v github.com/go-critic/go-critic/...)"
    exit 1
fi

PASS=true

for FILE in $STAGED_GO_FILES; do
    printf ">> \033[32m$FILE\033[0m"

    if [[ ! -f $FILE ]]; then
        printf ">> \033[32m$FILE\033[93m missing. Probably deleted. Will skip\033[0m\n"
        echo
        continue
    else
        printf "\n"
    fi

    #
    # Formatting
    #

    # Run gofmt on the staged file
    COMMAND="gofmt -l -w $FILE"
    printf "\t\033[90m$COMMAND\033[0m ... "
    $COMMAND
    printf "\033[32mOK\033[0m\n"

    # Run goimports on the staged file
    COMMAND="$GOIMPORTS -w $FILE"
    printf "\t\033[90m$COMMAND\033[0m ... "
    $COMMAND
    printf "\033[32mOK\033[0m\n"

    #
    # Linting
    #

    # Run golint on the staged file and check the exit status
    COMMAND="$GOLINT -set_exit_status $FILE"
    printf "\t\033[90m$COMMAND\033[0m ... "
    $COMMAND &> /tmp/__pre_commit_go__
    if [[ $? == 1 ]]; then
        printf "\033[31mFAILURE!\033[0m\n"
        printf "\033[31m$(cat /tmp/__pre_commit_go__)\033[0m\n"
        PASS=false
    else
        printf "\033[32mOK\033[0m\n"
    fi

    # Run govet on the staged file and check the exit status
    COMMAND="go vet $FILE"
    printf "\t\033[90m$COMMAND\033[0m ... "
    $COMMAND &> /tmp/__pre_commit_go__
    if [[ $? == 1 ]]; then
        printf "\033[31mFAILURE!\033[0m\n"
        printf "\033[31m$(cat /tmp/__pre_commit_go__)\033[0m\n"
        PASS=false
    else
        printf "\033[32mOK\033[0m\n"
    fi

    # # Run golangci-lint on the staged file and check the exit status
    # COMMAND="$GOLANGCILINT run $FILE"
    # printf "\t\033[90m$COMMAND\033[0m ... "
    # $COMMAND #&> /tmp/__pre_commit_go__
    # if [[ $? == 1 ]]; then
    #     printf "\033[31mFAILURE!\033[0m\n"
    #     printf "\033[31m$(cat /tmp/__pre_commit_go__)\033[0m\n"
    #     PASS=false
    # else
    #     printf "\033[32mOK\033[0m\n"
    # fi

    #
    # Analysis
    #

    # Run gocyclo on the staged file and check the exit status
    COMMAND="$GOCYCLO -over=15 $FILE"
    printf "\t\033[90m$COMMAND\033[0m ... "
    $COMMAND &> /tmp/__pre_commit_go__
    if [[ $? == 1 ]]; then
        printf "\033[31mFAILURE!\033[0m\n"
        printf "\033[31m$(cat /tmp/__pre_commit_go__)\033[0m\n"
        PASS=false
    else
        printf "\033[32mOK\033[0m\n"
    fi

    # Run gocritic on the staged file and check the exit status
    COMMAND="$GOCRITIC check $FILE"
    printf "\t\033[90m$COMMAND\033[0m ... "
    # if [[ $MACHINE_OS != "Windows" ]]; then
        echo $COMMAND &> /tmp/__pre_commit_go__
        if [[ $? == 1 ]]; then
            printf "\033[31mFAILURE!\033[0m\n"
            printf "\033[31m$(cat /tmp/__pre_commit_go__)\033[0m\n"
            PASS=false
        else
            printf "\033[32mOK\033[0m\n"
        fi
    # else
    #     printf "\033[32mSkiping on Windows\033[0m\n"
    # fi

    #
    # Unit Testing
    #
    echo $FILE | grep "_test.go" &> /dev/null
    if [[ $? -eq 0 ]]; then
        # printf "\033[31mUnit testing has been disabled until SMB\\Guest user issues is solved.\033[0m\n"
        cd $(dirname $FILE)
        # Run gocritic on the staged file and check the exit status
        COMMAND="go test -tags=unit -timeout 30s -short -v"
        printf "\t\033[90m$COMMAND\033[0m ... "
        $COMMAND &> /tmp/__pre_commit_go__
        if [[ $? != 0  ]]; then
            printf "\033[31mFAILURE!\033[0m\n"
            printf "\033[31m$(cat /tmp/__pre_commit_go__)\033[0m\n"
            PASS=false
        else
            printf "\033[32mOK\033[0m\n"
        fi
        cd $RUNNING_PATH
    fi


    #
    # Re-add changed file
    #
    if $PASS; then
        git add $FILE
    fi

    # exit 0
done

echo
echo

if ! $PASS; then
    printf "\033[0;30m\033[31mCOMMIT FAILED\033[0m\n"
    exit 1
else
    printf "\033[0;30m\033[42mCOMMIT SUCCEEDED\033[0m\n"
fi

echo
echo

exit 0
