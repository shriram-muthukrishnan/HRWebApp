package com.hrwebapp.web;

import com.google.gson.Gson;
import com.google.gson.reflect.TypeToken;
import com.hrwebapp.bean.JdbcBean;
import com.hrwebapp.bean.JdbcBeanImpl;
import com.hrwebapp.entity.Employee;
import java.io.IOException;
import java.io.PrintWriter;
import java.util.ArrayList;
import java.util.List;
import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.Cookie;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;

@WebServlet(name = "WebController", urlPatterns = {"/WebController"})
public class WebController extends HttpServlet {

  private static final String INCREMENT_PCT = "incrementPct";
  private static final String ID_KEY = "id";
  private static final String FN_KEY = "firstName";
  private static final String LOGOUT = "logout";

  JdbcBean jdbcBean = new JdbcBeanImpl();

  private void reportError(HttpServletResponse response, String message)
      throws ServletException, IOException {
    response.setContentType("text/html;charset=UTF-8");

    try (PrintWriter out = response.getWriter()) {
      out.println("<!DOCTYPE html>");
      out.println("<html>");
      out.println("<head>");
      out.println("<title>Servlet WebController</title>");
      out.println("</head>");
      out.println("<body>");
      out.println("<h1>" + message + "</h1>");
      out.println("</body>");
      out.println("</html>");
    }
  }

  protected void processRequest(HttpServletRequest request, HttpServletResponse response)
      throws ServletException, IOException {
    Gson gson = new Gson();

    String value;
    List<Employee> employeeList;
    if ((value = request.getParameter(ID_KEY)) != null) {
      int empId = Integer.parseInt(value);
      employeeList = jdbcBean.getEmployee(empId);
    } else if ((value = request.getParameter(FN_KEY)) != null) {
      employeeList = jdbcBean.getEmployeeByFn(value);
    } else if ((value = request.getParameter(LOGOUT)) != null) {
      HttpSession session = request.getSession(false);
      if (request.isRequestedSessionIdValid() && session != null) {
        session.invalidate();
      }
      handleLogOutResponse(request, response);
      response.setStatus(HttpServletResponse.SC_UNAUTHORIZED);
      employeeList = null;
    } else {
      employeeList = jdbcBean.getEmployees();
    }

    if (employeeList != null) {
      response.setContentType("application/json");
      gson.toJson(employeeList, new TypeToken<ArrayList<Employee>>() {}.getType(), response.getWriter());
    } else {
      response.setStatus(HttpServletResponse.SC_NOT_FOUND);
    }
  }

  private void handleLogOutResponse(HttpServletRequest request, HttpServletResponse response) {
    Cookie[] cookies = request.getCookies();
    if (cookies == null) {
      return;
    }
    for (Cookie cookie : cookies) {
      cookie.setMaxAge(0);
      cookie.setValue(null);
      cookie.setPath("/");
      cookie.setHttpOnly(true);
      cookie.setSecure(request.isSecure());
      response.addCookie(cookie);
    }
  }

  @Override
  protected void doGet(HttpServletRequest request, HttpServletResponse response)
      throws ServletException, IOException {
    processRequest(request, response);
  }

  @Override
  protected void doPost(HttpServletRequest request, HttpServletResponse response)
      throws ServletException, IOException {
    String value;
    if ((value = request.getParameter(INCREMENT_PCT)) != null) {
      Gson gson = new Gson();
      response.setContentType("application/json");
      List<Employee> employeeList = jdbcBean.incrementSalary(Integer.parseInt(value));
      gson.toJson(employeeList, new TypeToken<ArrayList<Employee>>() {}.getType(), response.getWriter());
    } else {
      response.setStatus(HttpServletResponse.SC_NOT_FOUND);
    }
  }

  @Override
  public String getServletInfo() {
    return "JdbcWebServlet: Reading employees table using JDBC and transforming it as JSON.";
  }
}
