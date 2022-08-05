<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ page import="com.beanlib.Authentication" %> 
<%@ page errorPage="error.jsp" %>
<jsp:useBean id="login" class="com.beanlib.Authentication"></jsp:useBean> <!-- the scope is page by default -->

<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8" name="viewport" content="width=device-width, initial-scale=1">
<link rel="stylesheet" href="${pageContext.request.contextPath}/css/styles.css">

<title>Please log on to the PROA Workflow System</title>
</head>

<body>
	<header>
		<h1>Peer Review of Assessment Workflow System</h1>
	</header>

	<form method="post">
		<div class="container">
			<label for="email">Email:</label>
			<input type="text" id="email" placeholder="Enter Email Address" name="email" required>
			<label for="password">Password:</label>
			<input type="password" id="password" placeholder="Enter Password" name="password" required> 
			<label for="loginrole">Choose your role:</label> 
			<select id="loginrole" name="loginrole" class="loginrole" required>
				<option>Choose your role from here</option>
				<option value="nlic">National Lecturer in Charge</option>
				<option value="pr">Peer Reviewer</option>
				<option value="dh">Discipline Head</option>
				<option value="lt">Learning and Teaching Officer</option>
			</select> 
			<br><br>
			<button type="submit" name="btn_login" id="btn_submit">Login</button> <!-- the class attribute was replaced with the id attribute -->
		</div>
	</form>

	<form method="post" action="register.jsp">
		<div class="container">
			<label for="btn_sign_up_or_sign_in">No account?</label>
			<button type="submit" id="btn_sign_up_or_sign_in">Sign Up Here</button> <!-- MODIFIED: the class attribute can be omitted -->
		</div>
	</form>

	<%
	// If the client has already logged in, redirect to the home (home.jsp)
	if (session.getAttribute("login") != null) {
		response.sendRedirect("home.jsp");
	}
	%>

	<!-- pass user input to login Bean class -->
	<jsp:setProperty name="login" property="email" param="email" />
	<jsp:setProperty name="login" property="password" param="password" />
	<jsp:setProperty name="login" property="loginrole" param="loginrole" />
		 		
	<%
	// get user input from the form
	String email = request.getParameter("email"); 
	String password = request.getParameter("password");
	String loginrole = request.getParameter("loginrole");
	
	// if login button is clicked
	if (request.getParameter("btn_login") != null) {
		// If the user has successfully logged in 
		if (login.validateLogin() == 1) {
			// set session information 
			session.setAttribute("login", email);
			session.setAttribute("loginrole", loginrole);
			// redirect to the home
			response.sendRedirect("home.jsp");
		}
		// If the user's account has not activated
		else if (login.validateLogin() == 0) {
			out.println("<font color=\"#cc0000\"><h2>Account not activated. " +
							"Please refer to the account activation email!</h2></font>");
		}
		// If the user's role is not assigned
		else if (login.validateLogin() == -1) {
			out.println("<font color=\"#cc0000\"><h2>Please choose the right role!</h2></font>");
		// If the user's login is unsuccessful
		}
		else {
			out.println("<font color=\"#cc0000\"><h2>Invalid password or username (email). " + 
							"Please log in again!</h2></font>");
		}
	}
	%>

</body>
</html>
