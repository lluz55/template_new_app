package main

import (
	"fmt"
	"os"

	"tpl_new_app/cli/cmd"
)

func main() {
	if err := cmd.Execute(os.Args[1:]); err != nil {
		fmt.Fprintln(os.Stderr, "erro:", err)
		os.Exit(1)
	}
}
