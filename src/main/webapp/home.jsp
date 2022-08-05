<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ page errorPage="error.jsp" %>

<!DOCTYPE html>
<html>
<head>
<meta charset="UTF-8">
<title>The PRoAWorkflow System</title>
</head>

<body>
	<%
	// Test if the user has logged in, the unauthorised user will be redirected to the login page
	if (session.getAttribute("login") == null || session.getAttribute("login") == " ") {
		response.sendRedirect("index.jsp");
	}
	// Based on their "loginrole", redirect to the right homepage of each role
	switch (String.valueOf(session.getAttribute("loginrole"))) {
		case "lt": response.sendRedirect("lt.jsp"); break;
		case "dh": response.sendRedirect("dh.jsp"); break;
		case "nlic": response.sendRedirect("nlic.jsp"); break;
		case "pr": response.sendRedirect("pr.jsp");
	}
	%>

</body>
</html>
