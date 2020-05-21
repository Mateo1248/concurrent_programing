package main

type Product struct {
	result float32
	emp    Employee
}

var setProChan = make(chan Product)
var getProChan = make(chan chan *Product)
var proWarehouseFull = make(chan bool)
