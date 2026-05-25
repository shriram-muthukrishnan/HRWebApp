package com.hrwebapp.web;

import java.io.IOException;
import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

@WebServlet(name = "GetRole", urlPatterns = {"/getrole"})
public class GetRole extends HttpServlet {

  private static final String[] ROLES = {"manager", "staff"};

  @Override
  protected void doGet(HttpServletRequest request, HttpServletResponse response)
      throws ServletException, IOException {

    response.setContentType("text/plain;charset=UTF-8");
    String returnValue = "anonymous";
    for (String role : ROLES) {
      if (request.isUserInRole(role)) {
        returnValue = role;
        break;
      }
    }

    response.getWriter().print(returnValue);
  }

  @Override
  public String getServletInfo() {
    return "JdbcWebServlet: Returns authenticated user role.";
  }
}
