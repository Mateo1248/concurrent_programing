package main

import (
	"fmt"
	"math/rand"
	"time"
)

type Customer struct {
	name string
	resp chan *Product
}

func (c Customer) buyProducts() {
	for {
		time.Sleep(time.Duration(rand.Intn(CUSTOMER_DELAY)) * time.Second)

		getProChan <- c.resp
		product := <-c.resp

		if product != nil {
			writeChan <- c.name + " buy product { " + fmt.Sprintf("%f", product.result) + " " + product.emp.name + " }"
		} else {
			writeChan <- "[firm error] " + c.name + " waiting for products."
		}

	}
}
