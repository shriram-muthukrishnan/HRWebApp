# Overview of the HR Web Application

**HR Web Application** is a Java web application that uses PostgreSQL JDBC with Azure Database for PostgreSQL Flexible Server.

It follows MVC (Model, View, Controller) architecture. The presentation layer uses HTML, JavaScript, jQuery, and CSS. The controller is a servlet that talks to PostgreSQL through Java beans. Maven is used for building the application.

The application uses the HR schema `employees` table and supports listing employees, searching by employee ID/name, and salary increment operations.

For database connectivity, the application defaults to Microsoft Entra ID Managed Identity authentication for PostgreSQL.
