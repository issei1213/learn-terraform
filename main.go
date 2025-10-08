package main

import "fmt"

// Customer represents a customer entity
type Customer struct {
	ID    int
	Name  string
	Email string
}

func main() {
	// Create a new customer instance
	customer := Customer{
		ID:    1,
		Name:  "John Doe",
		Email: "john.doe@example.com",
	}

	// Display customer information
	fmt.Printf("Customer ID: %d\n", customer.ID)
	fmt.Printf("Customer Name: %s\n", customer.Name)
	fmt.Printf("Customer Email: %s\n", customer.Email)
}
