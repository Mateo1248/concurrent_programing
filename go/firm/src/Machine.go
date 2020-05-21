package main

import (
	"math/rand"
	"sync"
	"time"
)

var machines = make([]Machine, MACHINE_ADD+MACHINE_MULT)

type Machine struct {
	id        int
	engine    Operation
	taskChan  chan Task
	queueChan chan chan *Task
	backdoor  chan bool
	damaged   bool
}

/*
Machine consructor
*/
func NewMachine(id int, engine Operation) Machine {
	return Machine{id, engine, make(chan Task), make(chan chan *Task), make(chan bool), false}
}

func (m *Machine) run() {

	//backdoor handler
	go func() {
		for {
			select {
			case <-m.backdoor:
				m.setDamaged(false)
			}
		}
	}()

	//main loop
	for {
		select {
		case respChan := <-m.queueChan:
			select {
			//if employee still waiting you will get a task
			case task := <-m.taskChan:
				//wait for a while
				time.Sleep(time.Duration(MACHINE_DELAY) * time.Millisecond)
				//do the task
				if m.isDamaged() {
					task.result = nil
				} else {
					result := m.engine.result(task.x, task.y)
					task.result = &result
					m.setDamaged(rand.Float64() < MACHINE_DAMAGE)
				}

				//send task
				respChan <- &task
			}
		}

	}
}

func (m Machine) getType() string {
	return m.engine.name
}

func (m Machine) getID() int {
	return m.id
}

func (m *Machine) isDamaged() bool {
	mutex := sync.Mutex{}
	mutex.Lock()
	defer mutex.Unlock()
	return m.damaged
}

func (m *Machine) setDamaged(x bool) {
	mutex := sync.Mutex{}
	mutex.Lock()
	defer mutex.Unlock()
	m.damaged = x
}
