CREATE TABLE Rooms  
(
  num_of_room INT(5) NOT NULL PRIMARY KEY,  
  num_of_beds INT(5) NOT NULL,
  balcony ENUM('TRUE','FALSE') NOT NULL  
  floor INT(5) NOT NULL,
  jacuzzi ENUM('TRUE','FALSE') NOT NULL,
  mini_bar ENUM('TRUE','FALSE') NOT NULL
)
ENGINE = innoDB
DEFAULT CHARSET = utf8
COLLATE = utf8_unicode_ci;

CREATE TABLE Customers
(
    num_of_customer INT(10) NOT NULL AUTO_INCREMENT,
    id INT(15),  
    first_name VARCHAR(30) NOT NULL,
    last_name VARCHAR(30) NOT NULL,    
    tel VARCHAR(30) NOT NULL,  
    street VARCHAR(30),
    num_of_home INT(5),
    num_of_entrance INT(5),    
    house_apartment INT(5),
    email VARCHAR(30), 
    city VARCHAR(30),
    state VARCHAR(30),
    PRIMARY KEY(num_of_client)  
)
ENGINE = innoDB
DEFAULT CHARSET = utf8
COLLATE = utf8_unicode_ci;  

CREATE TABLE Orders  
(
    order_number INT(10) PRIMARY KEY,  
    date_of_registration DATE NOT NULL, 
    check_in_date DATE NOT NULL,
    check_out_date DATE NOT NULL   
)
ENGINE = innoDB
DEFAULT CHARSET = utf8  
COLLATE = utf8_unicode_ci;

CREATE TABLE Customer_for_order
(
    order_number INT(10) NOT NULL,
    num_of_customer INT(10),      
    PRIMARY KEY(order_number),
    FOREIGN KEY (order_number) 
        REFERENCES Orders(order_number) 
        ON DELETE CASCADE,
    FOREIGN KEY (num_of_customer) 
        REFERENCES Customers(num_of_customer)
        ON DELETE CASCADE  
)
ENGINE = innoDB 
DEFAULT CHARSET = utf8
COLLATE = utf8_unicode_ci;


CREATE TABLE Room_of_order
(
    order_number INT(10), 
    num_of_room INT(5),   
    PRIMARY KEY(order_number,num_of_room), 
    FOREIGN KEY (order_number) 
        REFERENCES Orders(order_number)
        ON DELETE CASCADE,    
    FOREIGN KEY (num_of_room)
        REFERENCES Rooms(num_of_room)
        ON UPDATE CASCADE    
)
ENGINE = innoDB  
DEFAULT CHARSET = utf8 
COLLATE = utf8_unicode_ci;

CREATE TABLE Status
(
    num_of_status INT(5) PRIMARY KEY, 
    description VARCHAR(40)  
)
ENGINE = innoDB 
DEFAULT CHARSET = utf8  
COLLATE = utf8_unicode_ci


CREATE TABLE Order_status
(
    order_number INT(10) PRIMARY KEY,
    num_of_status INT(5),
    FOREIGN KEY (order_number)  
        REFERENCES Orders(order_number)
        ON DELETE CASCADE  
)
ENGINE = innoDB
DEFAULT CHARSET = utf8
COLLATE = utf8_unicode_ci; 


CREATE TABLE Malfunction_details
(
    num_of_malfunction INT(10) PRIMARY KEY, 
    description VARCHAR(40)  
)
ENGINE = innoDB DEFAULT CHARSET = utf8
COLLATE = utf8_unicode_ci;


CREATE TABLE Invalids_rooms  
(
    num_of_room INT(10),
    invalidity_start_date DATE,
    invalidity_end_date DATE,  
    num_of_malfunction INT(10),
    PRIMARY KEY(num_of_room,invalidity_start_date,
                invalidity_end_date,num_of_malfunction),   
    FOREIGN KEY (num_of_room) 
        REFERENCES Rooms(num_of_room) 
        ON DELETE CASCADE,
    FOREIGN KEY (num_of_malfunction) 
        REFERENCES Malfunction_details(num_of_malfunction) 
        ON UPDATE CASCADE   
)

ENGINE=innoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;


CREATE TABLE Satisfcation
(
    num INT(5) PRIMARY KEY, 
    num_grade INT(5)    
)
ENGINE = innoDB DEFAULT CHARSET = utf8
COLLATE = utf8_unicode_ci;


CREATE TABLE Order_satisfaction
(
    order_number INT(10) PRIMARY KEY,
    num INT(5),       
    FOREIGN KEY (order_number)
        REFERENCES Orders(order_number)
        ON DELETE CASCADE  
) 
ENGINE = innoDB DEFAULT CHARSET = utf8  
COLLATE = utf8_unicode_ci;demo
-- Available rooms query
SELECT 
    valid_rooms_availabe.num_rooms
FROM
    (SELECT 
        r.num_of_room AS num_rooms
    FROM
        Rooms r
    WHERE
        NOT EXISTS (SELECT 
                ir.num_of_room
            FROM
                Invalids_rooms ir
            WHERE
                (r.num_of_room = ir.num_of_room
                    AND '2022-06-04' BETWEEN ir.invalidity_start_date
                    AND ir.invalidity_end_date))) AS valid_rooms_availabe
WHERE
    NOT EXISTS (SELECT 
            roo.num_of_room
        FROM
            Room_of_order roo
                JOIN
            Orders o ON o.order_number = roo.order_number
                JOIN
            Order_status os ON o.order_number = os.order_number
                JOIN
            Status s ON s.num_of_status = os.num_of_status
        WHERE
            (valid_rooms_availabe.num_rooms = roo.num_of_room
                AND '2022-06-04' BETWEEN o.check_in_date AND o.check_out_date
                AND s.description <> 'cancelled'));
                
                
-- Rooms awaiting housekeeping
SELECT 
    r.num_of_room
FROM
    Rooms r
        JOIN
    Room_of_order roo ON r.num_of_room = roo.num_of_room
        JOIN
    Orders o ON roo.order_number = o.order_number
        JOIN
    Order_status os ON o.order_number = os.order_number
        JOIN
    Status s ON s.num_of_status = os.num_of_status
WHERE
    o.check_out_date = '2022-06-04'
        AND s.description = 'check out ';
        
        
        
-- Room with highest average satisfaction        
SELECT 
    max.max,
    average_grade1.num_room_max
FROM
    (SELECT 
        MAX(average_grade.average_grade_to_room) AS max
    FROM
        (SELECT 
            AVG(os.num) AS average_grade_to_room,
                roo.num_of_room AS num_room
        FROM
            Order_satisfaction os
                JOIN
            Orders o ON o.order_number = os.order_number
                JOIN
            Room_of_order roo ON roo.order_number = o.order_number
        GROUP BY roo.num_of_room) AS average_grade) AS max
        JOIN
    (SELECT 
        AVG(os1.num) AS average_grade_to_room1,
            roo1.num_of_room AS num_room_max
    FROM
        Order_satisfaction os1
            JOIN
        Orders o1 ON o1.order_number = os1.order_number
            JOIN
        Room_of_order roo1 ON roo1.order_number = o1.order_number
    GROUP BY roo1.num_of_room) AS average_grade1 ON max.max = average_grade1.average_grade_to_room1;

        
-- Customer with most bookings        
SELECT 
    max1.num_orders,
    max1.num_customer,
    customers1.first_name,
    customers1.last_name
FROM
    (SELECT 
        num_of_orders_to_customer1.num_of_orders1 AS num_orders,
            num_of_orders_to_customer1.num_of_customer1 AS num_customer
    FROM
        (SELECT 
            cfo1.num_of_customer2 AS num_of_customer1,
                COUNT(cfo1.num_of_order2) AS num_of_orders1
        FROM
            (SELECT 
                cfo2.num_of_customer AS num_of_customer2,
                    cfo2.order_number AS num_of_order2
            FROM
                Customer_for_order cfo2
                    JOIN
                Order_status os ON os.order_number = cfo2.order_number
                    JOIN
                Status s ON os.num_of_status = s.num_of_status
            WHERE
                s.description <> 'cancelled') AS cfo1
        GROUP BY num_of_customer1) AS num_of_orders_to_customer1
            JOIN
        (SELECT 
            MAX(num_of_orders_to_customer.num_of_orders) AS max
        FROM
            (SELECT 
                cfo.num_of_customer AS num_of_customer,
                    COUNT(cfo.order_number) AS num_of_orders
            FROM
                Customer_for_order cfo
            GROUP BY cfo.num_of_customer) AS num_of_orders_to_customer) AS max
        WHERE
            max.max = num_of_orders_to_customer1.num_of_orders1) AS max1
        JOIN
    (SELECT 
        c.first_name AS first_name,
            c.last_name AS last_name,
            c.num_of_customer AS num_of_customer
    FROM
        Customers c) AS customers1
WHERE
    customers1.num_of_customer = max1.num_customer;