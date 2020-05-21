package main

var taskWarehouseFullChan = make(chan bool)
var setTaskChan = make(chan Task)
var getTaskChan = make(chan chan *Task)

//task
type Task struct {
	x             float32
	operationName string
	y             float32
	result        *float32
}

//operation
type Operation struct {
	name   string
	result func(x, y float32) float32
}

var operations = []Operation{
	{"+", func(x, y float32) float32 { return x + y }},
	{"*", func(x, y float32) float32 { return x * y }},
	{"-", func(x, y float32) float32 { return x - y }},
}
