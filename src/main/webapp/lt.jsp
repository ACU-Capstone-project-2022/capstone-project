<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ page import="com.beanlib.Authentication" %>
<%@ page errorPage="error.jsp" %>
<jsp:useBean id="login" class="com.beanlib.Authentication"></jsp:useBean>

<!DOCTYPE html>
<html>
<head>
<meta charset="UTF-8" name="viewport" content="width=device-width, initial-scale=1">
<link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/4.7.0/css/font-awesome.min.css">
<link rel="stylesheet" href="${pageContext.request.contextPath}/css/styles.css">
<link rel="stylesheet" href="https://fonts.googleapis.com/icon?family=Material+Icons">

<title>Learning and Teaching Officer Dashboard</title>
</head>

<body>
	<%
	String user = "";
	// If the user has not logged in yet, the unauthorised user needs to log in first
	if (session.getAttribute("login") == null || session.getAttribute("login") == " ") {
		response.sendRedirect("index.jsp");
	}
	else {
		// return user info based on login account
		user = login.getUser(session.getAttribute("login").toString());
		// Get user info from changing the attributes in "login" to String
		// then use it as the variable named user
	}
	%>
	
	<header>
		<h1>Peer Review of Assessment Workflow System</h1>
		<h2>Welcome, <%= user %></h2>
		<h2>You log in as a Learning and Teaching Officer.</h2>
	</header>
	
	<ul>
		<li class="li_main_menu">
			<a href="import.jsp"> <!-- the class attribute (class="mainmenu") was omitted becuase it was not used. -->
			<i class="material-icons main-menu-img" style="font-size:120px;color:#3c1a50">attachment</i>
			<br>Import Units Data</a>
		</li>
		<li class="li_main_menu">
			<a href="nominate_units.jsp">
			<i class="material-icons main-menu-img" style="font-size:120px;color:#3c1a50">assignment_ind</i>
			<br>Nominate Units for Review</a>
		</li>
		<li class="li_main_menu">
			<a href="check_assessments.jsp?role=lt">
			<i class="material-icons main-menu-img" style="font-size:120px;color:#3c1a50">verified_user</i>
			<br>Check Compliance of Assessments</a>
		</li>
	</ul>
	
	<br><br>
	
	<footer>
		<nav><ul>
			<li><a href="password.jsp"><button class="btn_sub_menu"><i class="fa fa-lock"></i> Change Password</button></a></li>
			<li><a href="logout.jsp"><button class="btn_sub_menu"><i class="fa fa-sign-out"></i> Logout</button></a></li>
		</ul></nav>
	</footer>
</body>
</html>
