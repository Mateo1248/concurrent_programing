package main

import (
	"bufio"
	"container/list"
	"fmt"
	"math/rand"
	"os"
	"os/exec"
	"strconv"
	"time"
)

var getProductsChan = make(chan *list.List)
var getTasksChan = make(chan *list.List)
var writeChan = make(chan string)

func calmInterface() {
	reader := bufio.NewReader(os.Stdin)

	for {
		fmt.Println("1 - Tasks state\n2 - Products state\n3 - Employees stat")
		line, _ := reader.ReadString('\n')

		cmd := exec.Command("clear")
		cmd.Stdout = os.Stdout
		cmd.Run()

		switch line {
		case "1\n":
			getTasksChan <- nil
			tasksList := <-getTasksChan
			for l := tasksList.Front(); l != nil; l = l.Next() {
				fmt.Println(l.Value)
			}
		case "2\n":
			getProductsChan <- nil
			productList := <-getProductsChan
			for p := productList.Front(); p != nil; p = p.Next() {
				fmt.Println("{", p.Value.(Product).result, p.Value.(Product).emp.name, "}")
			}
		case "3\n":
			for _, e := range employees {
				e.getStat()
			}
		default:
			fmt.Println("Bad option!")
		}
	}
}

func main() {
	rand.Seed(time.Now().UTC().UnixNano())

	//product list manager
	go func() {
		var productList = list.New()

		for {
			select {
			case prod := <-setProChan:
				if productList.Len() <= PRODUCT_SIZE {
					productList.PushBack(prod)
					proWarehouseFull <- false
				} else {
					proWarehouseFull <- true
				}
			case respChan := <-getProChan:
				if productList.Len() > 0 {
					pro := productList.Front().Value.(Product)
					respChan <- &pro
					productList.Remove(productList.Front())
				} else {
					respChan <- nil
				}
			case <-getProductsChan:
				getProductsChan <- productList
			}
		}
	}()

	//task list manager
	go func() {
		var taskList = list.New()

		for {
			select {
			case task := <-setTaskChan:
				if taskList.Len() <= PRODUCT_SIZE {
					taskList.PushBack(task)
					taskWarehouseFullChan <- false
				} else {
					taskWarehouseFullChan <- true
				}
			case respChan := <-getTaskChan:
				if taskList.Len() > 0 {
					pro := taskList.Front().Value.(Task)
					respChan <- &pro
					taskList.Remove(taskList.Front())
				} else {
					respChan <- nil
				}
			case <-getTasksChan:
				getTasksChan <- taskList
			}
		}
	}()

	// mode 1 writer
	go func() {
		if MODE == 1 {
			for {
				select {
				case msg := <-writeChan:
					fmt.Println(msg)
				}
			}
		} else {
			for {
				select {
				case <-writeChan:
				}
			}
		}
	}()

	if len(os.Args) == 2 && (os.Args[1] == "1" || os.Args[1] == "2") {
		MODE, _ = strconv.Atoi(os.Args[1])

		service := Service{}
		go service.run()

		boss := Boss{"Boss"}
		go boss.makeTasks()

		//run machines
		for i := 0; i < MACHINE_ADD; i++ {
			machines[i] = NewMachine(i, operations[0])
			go machines[i].run()
		}

		for i := MACHINE_ADD; i < MACHINE_MULT+MACHINE_ADD; i++ {
			machines[i] = NewMachine(i, operations[1])
			go machines[i].run()
		}

		//run employees
		for i := 0; i < EMPLOYEE_AMOUNT; i++ {
			employees[i] = Employee{name: "Employee" + strconv.Itoa(i), patient: rand.Intn(2) == 1, proStat: 0, taskChan: make(chan *Task)}
			go employees[i].makeProducts()
		}

		//run customers
		for i := 0; i < CUSTOMER_AMOUNT; i++ {
			var c = Customer{"Customer" + strconv.Itoa(i), make(chan *Product)}
			go c.buyProducts()
		}

		//spokojny
		if MODE == 2 {
			go calmInterface()
		}

		for {
			time.Sleep(time.Second * 10)
		}
	} else {
		fmt.Println("Start-up example:\n./Firm <argument>\nArgument: 1-talkative, 2-calm")
	}
}
