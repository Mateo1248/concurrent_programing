package main

import (
	"fmt"
	"math/rand"
	"time"
)

type Boss struct {
	name string
}

func (b Boss) makeTasks() {
	for {
		time.Sleep(time.Duration(rand.Intn(BOSS_DELAY)) * time.Second)

		task := createTask(rand.Float32()*float32(ARG_RANGE), rand.Float32()*float32(ARG_RANGE), operations[rand.Intn(2)].name)

	setTaskLoop:
		for {
			setTaskChan <- task

			//check if set task went successfully
			if <-taskWarehouseFullChan {
				writeChan <- "[firm error] " + "Tasks warehouse full, boss waiting !!!"
				time.Sleep(time.Second)
			} else {
				break setTaskLoop
			}
		}

		writeChan <- b.name + " create task {" + fmt.Sprintf("%f", task.x) + " " + task.operationName + " " + fmt.Sprintf("%f", task.y) + "}"
	}
}

func createTask(x, y float32, operationName string) Task {
	return Task{x: x, y: y, operationName: operationName, result: nil}
}
