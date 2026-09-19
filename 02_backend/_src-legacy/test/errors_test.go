package errors

import (
	olderr "errors"
	"fmt"

	"docstore/src/common/errors"
	"testing"

	"github.com/stretchr/testify/assert"
)

// "github.com/IguteChung/go-errors"

func TestError1(t *testing.T) {
	errtxt := "something wrong"
	tracableerror := errors.New(errtxt)
	str := fmt.Sprintf("%s\n%s", tracableerror.Error(), errors.StackTrace(tracableerror))
	assert.GreaterOrEqual(t, len(str), len(errtxt))
}
func TestError2(t *testing.T) {
	errtxt := "something wrong"
	olderror := olderr.New(errtxt)
	str := fmt.Sprintf("%s\n%s", olderror.Error(), errors.StackTrace(olderror))
	assert.Equal(t, errtxt+"\n", str)
}

//
//func TestTableCompare(t *testing.T) {
//	var testInputs = []struct {
//		value int
//		min   int
//		max   int
//		ret   int
//	}{
//		{10, 9, 11, 10},
//		{9, 9, 11, 9},
//		{11, 9, 11, 11},
//		{8, 9, 11, 9},
//		{12, 9, 11, 11},
//	}
//	for _, test := range testInputs {
//		output := utils.CheckIntervalInt(test.value, test.min, test.max)
//		if output != test.ret {
//			t.Errorf("CheckIntervalInt failed: '%v, %v, %v' inputed, expected '%v' received: '%v'", test.value, test.min, test.max, test.ret, output)
//		}
//	}
//}
//
