package main

import (
	"fmt"
	"math/rand"
	"sync"
	"sync/atomic"
	"time"
)

var employees = make([]Employee, EMPLOYEE_AMOUNT)

type Employee struct {
	name        string
	patient     bool
	proStat     uint64
	taskChan    chan *Task
	serviceChan chan Machine
}

func (e *Employee) makeProducts() {
	for {
		time.Sleep(time.Duration(rand.Intn(EMPLOYEE_DELAY)) * time.Second)

		//get task from list
		getTaskChan <- e.taskChan
		task := <-e.taskChan

		if task != nil {

			i := rand.Intn(len(machines))

			var m Machine
		machineLoop:
			for {
				//match machine
				for ; machines[i].getType() != task.operationName; i = (i + 1) % MACHINE_LEN {
				}

				m = machines[i]

				switch e.patient {
				case true:

					select {
					case m.queueChan <- e.taskChan:
						select {
						case m.taskChan <- *task:
							break machineLoop
						}
					}

				case false:
					select {
					case m.queueChan <- e.taskChan:
						select {
						case m.taskChan <- *task:
							break machineLoop
						}
					case <-time.After(time.Duration(EMPLOYEE_WAIT) * time.Millisecond):
						i = (i + 1) % MACHINE_LEN

					}
				}
			}
			task = <-e.taskChan
			//check if machine create task property
			if task.result == nil {
				ServiceChan <- m
				writeChan <- "Machine" + fmt.Sprintf("%d", m.getID()) + " is broken !!!"
			} else {
				//create product and send to product list
				product := Product{*task.result, *e}

			setProductLoop:
				for {
					setProChan <- product

					if <-proWarehouseFull {
						writeChan <- "[firm error] " + "Products warehouse full, " + e.name + " waiting !!!"
						time.Sleep(time.Second)
					} else {

						atomic.AddUint64(&e.proStat, 1)
						break setProductLoop
					}
				}

				writeChan <- e.name + " create product {" + fmt.Sprintf("%f", product.result) + "} on machine" + fmt.Sprintf("%d", m.getID())
			}
		} else {
			writeChan <- "[firm error] " + e.name + " waiting for task."
		}
	}
}

func (e *Employee) repairMachines() {
	for {
		select {
		case m := <-e.serviceChan:
			time.Sleep(time.Duration((SERVICE_EMPLOYEE_DELAY)) * time.Second)
			m.backdoor <- true
			MachineFixed <- m.getID()
		}
	}
}

func (e Employee) getStat() {
	mutex := sync.Mutex{}
	mutex.Lock()
	defer mutex.Unlock()
	fmt.Println(e.name+" patient:", e.patient, "efficiency:", e.proStat)
}
