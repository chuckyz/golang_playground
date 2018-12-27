package main

import (
  "github.com/hashicorp/hcl"
  // "os"
  "io/ioutil"
  "fmt"
)

func main() {
	file, err := ioutil.ReadFile("tests/main.tf")
	if err != nil {
		fmt.Println(err)
	}
	parsed_hcl, err := hcl.Parse(string(file))
	fmt.Println(parsed_hcl)
	// parsed_hcl, err := hcl.ParseBytes(file)
	// if err != nil {
	// 	fmt.Println(err)
	// }
	// fmt.Println(parsed_hcl)
	// fmt.Println(parsed_hcl.Node.Pos)
}

