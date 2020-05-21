package main

import (
	"strconv"
)

var ServiceChan = make(chan Machine, MACHINE_LEN)
var MachineFixed = make(chan int)

type Service struct {
	serviceEmp []Employee
	fixedChan  chan int
}

func (s *Service) run() {
	//create employees
	s.serviceEmp = make([]Employee, SERVICE_EMPLOYEES)
	s.fixedChan = make(chan int)
	for i := 0; i < SERVICE_EMPLOYEES; i++ {
		s.serviceEmp[i] = Employee{name: "ServiceEmployee" + strconv.Itoa(i), proStat: 0, serviceChan: make(chan Machine)}
		go s.serviceEmp[i].repairMachines()
	}

	//main loop
	empIterator := 0
	done := 1000
	//count number of request without repair
	machineDmgCtr := make([]int, MACHINE_LEN)
	for {
		select {
		case m := <-ServiceChan:
			if m.id != done {
				s.serviceEmp[empIterator].serviceChan <- m
				empIterator = (empIterator + 1) % SERVICE_EMPLOYEES
			} else {
				machineDmgCtr[m.id]++
				for i := range machineDmgCtr {
					if machineDmgCtr[i] == 2 {
						//send employee one more time
						s.serviceEmp[empIterator].serviceChan <- m
						machineDmgCtr[i] = 0
						empIterator = (empIterator + 1) % SERVICE_EMPLOYEES
						break
					}
				}
			}
		case id := <-MachineFixed:
			done = id
			writeChan <- "Machine " + strconv.Itoa(id) + " repaired !!!"
		}
	}
}
