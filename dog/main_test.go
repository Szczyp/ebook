package main

import (
	"testing"
)

type Struc struct {
	A string;
	B int
}

func Test(t *testing.T) {
	test := Struc { A: "lol", B: 3}
	tests := []Struc{Struc { A: "lol", B: 2}}

	if test != tests[0] {
		t.Error(tests[0])
	}
}
