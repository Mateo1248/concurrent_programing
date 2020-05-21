with Ada.Text_IO;               
with Ada.Numerics.Float_Random; 
with Ada.Numerics.Discrete_Random;
with Ada.Command_Line;
with GNAT.OS_Lib;
use Ada.Command_Line;
use Ada.Text_IO;

procedure firm is
    package RF renames Ada.Numerics.Float_Random;

    --enum
    type Func is ('+', '*');
    type Mode is (CALM,TALKATIVE);


    --constant values
    FIRM_MODE       : Mode := TALKATIVE;
	BOSS_DELAY      : constant := 3.0;  

	TASK_SIZE       : constant := 20;

	EMPLOYEE_DELAY  : constant := 4.0;
	EMPLOYEE_AMOUNT : constant := 4;
    EMPLOYEE_WAIT   : constant := 0.2;

	PRODUCT_SIZE    : constant := 20;

	CUSTOMER_DELAY  : constant := 15.0;
	CUSTOMER_AMOUNT : constant := 8;

	ARG_RANGE       : constant := 100.0;

    MACHINE_ADD     : constant := 2;
    MACHINE_MULT    : constant := 2;
    MACHINE_DELAY   : constant := 1.5;
    MACHINE_DAMAGE  : constant := 0.2;

    SER_EMP_AMOUNT  : constant := 2;
    SER_EMP_DELAY   : constant := 0.5;

    
    --records
    type rTask is record
        x      : Float;
        f      : Func;
        y      : Float;
        result : Float;        
    end record;

    type rProduct is record
      value : Float;
      empId : Integer;
    end record;

    type rEmpStat is record 
        patient : boolean;
        stat    : integer;
    end record;


    --arrays
    type machineDmgCtr is array(0..SER_EMP_AMOUNT) of Integer;
    type taskAr is array(0..TASK_SIZE-1) of rTask;
    type productAr is array(0..PRODUCT_SIZE-1) of rProduct;
    type empStatAr is array(0..EMPLOYEE_AMOUNT-1) of rEmpStat;

    type fAr is array(0..1) of Func;
    funcAr : fAr := ('+', '*');


    --other procedures and functions
    procedure showMsg(message : String) is
    begin
        if (FIRM_MODE = TALKATIVE) then
            Put_Line(message);
        end if;
    end showMsg;
    
    --####################################################################
    --protected types
    --####################################################################
    --tasks
    protected type TaskProType is
        entry set (item : in rTask);
        entry get (item : out rTask);
        function getList(f, l : out Integer) return taskAr;
    private
        arr : taskAr;
        first, last, length : Integer := 0;
    end TaskProType;

    protected body TaskProType is 
        
        entry set (item : in rTask)
            when length < TASK_SIZE is
        begin
            arr(last) := item;
            last := (last + 1) mod TASK_SIZE;
            length := length + 1;
        end set;

        entry get (item : out rTask)
            when length > 0 is
        begin
            item := arr(first);
            first := (first + 1) mod TASK_SIZE;
            length := length - 1;
        end get;

        function getList(f, l : out Integer) return taskAr is 
        begin
            f := first;
            l := length;
            return arr;
        end getList;
    end TaskProType;

    taskPro : TaskProType;

    --products
    protected type ProductProType is
        entry set (item : in  rProduct);
        entry get (item : out rProduct);
        function getList(f, l : out Integer) return productAr;
    private
        arr : ProductAr;
        first, last, length : Natural := 0;
    end ProductProType;

    protected body ProductProType is 
        
        entry set (item : in rProduct)
            when length < PRODUCT_SIZE is
        begin
            arr(last) := item;
            last := (last + 1) mod PRODUCT_SIZE;
            length := length + 1;
        end set;

        entry get (item : out rProduct)
            when length > 0 is
        begin
            item := arr(first);
            first := (first + 1) mod PRODUCT_SIZE;
            length := length - 1;
        end get;

        function getList(f, l : out Integer) return productAr is 
        begin
            f := first;
            l := length;
            return arr;
        end getList;
    end ProductProType;

    productPro : ProductProType;

    --employees stat
     protected type EmpStatProType is
        procedure set(p : in Boolean ; i : in integer);
        entry incStat(i : in integer);
        entry getList(ar : out empStatAr);
    private
        arr : empStatAr;
        free : Boolean;
    end EmpStatProType;

    protected body EmpStatProType is 
        
        procedure set (p : in Boolean ; i : in integer) is
        begin
            arr(i).patient := p;
            arr(i).stat := 0;
            free := true;
        end set;

        entry incStat ( i : in integer)
        when free  is
        begin
            free := false;
            arr(i).stat := arr(i).stat + 1;
            free := true;
        end incStat;

        entry getList(ar : out empStatAr)
        when free is 
        begin
            free := false;
            ar := arr;
            free := true;
        end getList;
    end EmpStatProType;

    empStatPro : EmpStatProType;

    --machine backdoor
    protected type MachineBackdoorPro is
        procedure repair;
        procedure getStatus(broken : out Boolean);
        procedure setStatus(broken : in Boolean);
    private
        isbroken : Boolean := false;
    end MachineBackdoorPro;

    protected body MachineBackdoorPro is 
        
        procedure repair is 
        begin
            isbroken := false;
        end repair;

        procedure getStatus(broken : out Boolean) is
        begin
        broken := isbroken;
        end getStatus;

        procedure setStatus(broken : in Boolean) is
        begin
        isbroken := broken;
        end setStatus;

    end MachineBackdoorPro;

    type MachineBackdoorProAr is array(0..MACHINE_ADD+MACHINE_MULT) of MachineBackdoorPro;
    machineBackdoors : MachineBackdoorProAr;

    --####################################################################
    --task types
    --####################################################################
    task type Boss is 
        entry create;
    end Boss;
    
    task type Employee is 
        entry create(p : in Boolean ; idd : in integer);
    end Employee;

    task type Customer is
        entry create(i : in integer);
    end Customer;

    task type Machine is 
        entry doTask(t : in rTask ; r : out float);
        entry create(ff : in Func; idd : in integer);
        entry getType(ff : out Func);
    end Machine;

    task type Service is 
        entry reportBroken(id : in integer);
    end Service;

    task type SerEmployee is
        entry machineRepair(id : in integer);
        entry create(idd : in integer);
    end SerEmployee;

    oService    : Service;
    oBoss       : Boss;
    type serEmpAr is array(0..SER_EMP_AMOUNT-1) of SerEmployee;
    empAr       : serEmpAr;
    type employeeAr is array(0..EMPLOYEE_AMOUNT-1) of Employee;
    employees   : employeeAr;
    type customerAr is array(0..CUSTOMER_AMOUNT-1) of Customer;
    customers   : customerAr;
    type machineAr is array(0..MACHINE_ADD+MACHINE_MULT-1) of Machine;
    machines    : machineAr;


    --####################################################################
    --task bodies
    --####################################################################
    --Boss
    task body Boss is
        new_task   : rTask;
        type func_range is range fAr'First..fAr'Last;
        package RI is new Ada.Numerics.Discrete_Random(func_range);
        genF       : RF.Generator;
        genI       : RI.Generator;
    begin

        accept create do
            RF.Reset(genF);
            RI.Reset(genI);
        end create;
        loop
            delay Duration(BOSS_DELAY * RF.Random(GenF));

            new_task := (RF.Random(GenF) * ARG_RANGE,
                         funcAr(Integer(RI.Random(genI))),
                         RF.Random(GenF) * ARG_RANGE,
                         0.0);

            taskPro.set(new_task);
            showMsg("Boss create task" & Float'Image(new_task.x) & " " & Float'Image(new_task.y) & " " & Func'Image(new_task.f));
        end loop;
    end Boss;

    --Employee
    task body Employee is
        patient    : Boolean;
        id         : integer;
        empTask    : rTask;
        empProduct : rProduct;
        genF       : RF.Generator;
        stat       : integer := 0;
        machineLen : integer := MACHINE_ADD + MACHINE_MULT;
        type machRange is range machines'First..machines'Last;
        package RI is new Ada.Numerics.Discrete_Random(machRange);
        genI       : RI.Generator;
        machineID  : integer := 0;
        t          : Func;
    begin
        accept create(p : in Boolean ; idd : in integer) do
            patient := p;
            id := idd;
            empStatPro.set(patient, id);
            RF.Reset(genF);
            RI.Reset(genI);
        end create;

        loop
            delay Duration(EMPLOYEE_DELAY * RF.Random(GenF));
            taskPro.get(empTask);
            
            machineID := Integer(RI.Random(genI));

            machineLoop:
            loop
                --find machine with matchin type
                <<tryNextMachine>>

                findMachine:
                loop
                    machines(machineID).getType(t);
                    if t = empTask.f then
                        exit findMachine;
                    end if;
                    machineID := (machineID + 1) mod machineLen;
                end loop findMachine;

                case patient is 
                    when True =>
                        machines(machineID).doTask(empTask, empTask.result);
                        exit machineLoop;
                    when False =>
                        select 
                            machines(machineID).doTask(empTask, empTask.result);
                            exit machineLoop;
                        or
                            delay Duration(EMPLOYEE_WAIT);
                            --machine busy if not patient find another machine if patient try again
                            machineID := (machineID + 1) mod machineLen;
                            goto tryNextMachine;
                        end select;  
                end case;           
            end loop machineLoop;
            
            if empTask.result < 0.0 then
                showMsg("Machine" & Integer'Image(machineID) & " is broken!!!");
                oService.reportBroken(machineID);
            else
                empStatPro.incStat(id);
                empProduct := (empTask.result, id);
                ProductPro.set(empProduct);
                showMsg("Employee" & Integer'Image(id) & " make product" & Float'Image(empProduct.value) & " on machine" & Integer'Image(machineID));
            end if;
        end loop;
    end Employee;


    --Customer
    task body Customer is
        genF    : RF.Generator;
        product : rProduct;
        id      : integer;
    begin
        accept create(i : in integer) do
            id := i;
        end create;

        loop
            delay Duration(CUSTOMER_DELAY * RF.Random(GenF));
            productPro.get(product);
            showMsg("Customer" & Integer'Image(id) & " buy product " & Float'Image(product.value));
        end loop;
    end Customer;


    --Machine
    task body Machine is
        free   : Boolean;
        f      : Func;
        genF   : RF.Generator;
        broken : Boolean;
        id     : integer;
    begin
        accept create(ff : in Func; idd : in integer) do
            f := ff;
            free := true;
            broken := false;
            id := idd;
        end create;

        loop
            select
                accept doTask(t : in rTask ; r : out Float) do
                    machineBackdoors(id).getStatus(broken);
                    delay Duration(MACHINE_DELAY);

                    if broken then
                        r := -10.0;
                    else 
                        case f is
                            when '+' =>  r := t.x + t.y;
                            when '*' =>  r := t.x * t.y;
                        end case;
                        machineBackdoors(id).setStatus(RF.Random(genF)<MACHINE_DAMAGE);
                    end if; 
                end doTask;
            or
                accept getType(ff : out Func) do
                    ff := f;
                end getType;
            end select;
        end loop;
    end Machine;


    --Service
     task body Service is
        empIterator : integer := 0;
        broken      : boolean;
        lastFixed   : integer := 1000;
    begin
        loop
            select
                accept reportBroken(id : in Integer) do

                    machineBackdoors(id).getStatus(broken);

                    if broken and lastFixed /= id then
                        lastFixed := id;
                        empIterator := (empIterator + 1) mod SER_EMP_AMOUNT;
                        empAr(empIterator).machineRepair(id);
                    end if;
                end reportBroken;
            end select;
        end loop;
    end Service;


    --Service Employee
    task body SerEmployee is
        empId : integer;
    begin

        accept create(idd : in integer) do
            empId := idd;
        end create;

        loop
            select 
                accept machineRepair(id : in integer) do
                    delay Duration(SER_EMP_DELAY);
                    machineBackdoors(id).repair;
                    showMsg("Machine" & Integer'Image(id) & " repaired by an service employee" & Integer'Image(empId));
                end machineRepair;
            end select;
        end loop;
    end SerEmployee;


--####################################################################
--main
--####################################################################
begin
    if (Argument_Count < 1) then
        Put_Line("Start-up example:\n./Firm <argument>\nArgument: 1-talkative, 2-calm");
        GNAT.OS_Lib.OS_Exit (0);
    else       
        declare
                msg         : String(1..100);
                buffer      : Integer;
                tar         : taskAr;
                par         : productAr;
                est         : empStatAr;
                first, len  : Integer;
                pro         : rProduct;
                tas         : rTask;
                genF        : RF.Generator;
        begin 

            RF.Reset(genF);
            
            oBoss.create;

            empCreateLoop:
            for i in empAr'Range loop
                empAr(i).create(i);
            end loop empCreateLoop;

            mach: 
            for i in machines'Range loop
                if i < MACHINE_ADD then
                    machines(i).create('+', i);
                else
                    machines(i).create('*', i);
                end if;
            end loop mach;

            emp:
            for i in employees'Range loop
                employees(i).create(RF.Random(GenF)>0.50, i);
            end loop emp;

            cust:
            for i in customers'Range loop
                customers(i).create(i);
            end loop cust;


            if (Argument(1) = "1") then
                FIRM_MODE := TALKATIVE;
            elsif (Argument(1) = "2") then
                FIRM_MODE := CALM;
                loop
                    Put_Line("1 - Tasks state");
                    Put_Line("2 - Products state");
                    Put_Line("3 - Employees stat");
                    Get_Line(msg, buffer);
                    Put(ASCII.ESC & "[2J");

                    if(msg(1..buffer) = "1") then
                        tar := taskPro.getList(first, len);
                        for i in first..(first + len - 1) loop
                            tas := tar(i);
                            Put_Line("{" & Float'Image(tas.x) & " " & Float'Image(tas.y) & " " & Func'Image(tas.f) & "}");
                        end loop;

                    elsif(msg(1..buffer) = "2") then
                        par := productPro.getList(first, len);
                        for i in first..(first + len - 1) loop
                            pro := par(i);
                            Put_Line("{" & Float'Image(pro.value) & "}");
                        end loop;
                    elsif(msg(1..buffer) = "3") then
                        select
                            empStatPro.getList(est);
                            for i in est'Range loop
                                Put_Line("Employee id: " & Integer'Image(i) & " patient: " & Boolean'Image(est(i).patient) & " stat: " & Integer'Image(est(i).stat));
                            end loop;
                        or
                            delay 1.0;
                        end select;
                        
                    end if;
                end loop;
            end if;
        end;
    end if;
end firm;