package main

import (
	"fmt"

	"github.com/templ-project/go/src/pkg/hello"
	"github.com/templ-project/go/src/pkg/ver"
)

func main() {
	fmt.Println(hello.HelloWorld("World"))
	fmt.Println()
	ver.ShowVersion()
}
