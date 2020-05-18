package main

import (
	"fmt"

	"github.com/templ-project/go/src/pkg/hello"
)

func main() {
	fmt.Println(hello.HelloWorld("World"))
	fmt.Println()
	ShowVersion()
}
