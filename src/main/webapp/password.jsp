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

<title>Change your password</title>
</head>

<body>
	<header>
		<h1>Peer Review of Assessment Workflow System</h1>
		<h2>Change Your Password</h2>
	</header>

	<form method="post">
		<div class="container">
			<label for="email">Email:</label>
			<input type="text" placeholder="Enter Email Address" name="email" id="email" required>
			<label for="oldpassword">Old Password:</label>
			<input type="password" placeholder="Enter old password" name="password" id="oldpassword" required>
			<label for="newpassword">New Password:</label>
			<input type="password" placeholder="Enter new password" name="passwordNew" id="newpassword" required>
			<label for="newagain">New Password Again:</label>
			<input type="password" placeholder="Enter new password again" name="passwordAgain" id="newagain" required>
			<button type="submit" name="btn_change" id="btn_submit">Change</button>
		</div>
	</form>

	<form method="post" action="home.jsp">
		<div class="container">
			<button type="submit" id="backtohome"><i class="fa fa-home"></i> Back to Home</button>
		</div>
	</form>


	<%
	// If the user has not logged in yet, the unauthorised user needs to log in first
	if (session.getAttribute("login") == null || session.getAttribute("login") == " ") {
		response.sendRedirect("index.jsp");
		return;
	}
	%>
	
	<!-- pass user input to login Bean class -->
	<jsp:setProperty name="login" property="email" param="email" />
	<jsp:setProperty name="login" property="password" param="password" />
	<jsp:setProperty name="login" property="passwordNew" param="passwordNew" />

	<%
	// if change button is clicked
	if (request.getParameter("btn_change") != null) {
		String passnew = request.getParameter("passwordNew");
		String passagain = request.getParameter("passwordAgain");
		// If new password does not match
		if (!passnew.equals(passagain)) {
			out.println("<font color=\"#cc0000\"><h2>New and confirmed passwords do not match!</h2></font>");
		}
		// If password has successfully changed
		else if (login.changePassword() == 1) {
			session.invalidate(); // destroy session
			out.println("<font color=\"#3c1a50\"><h2>Password has succesfully changed." +
							" Please <a href = \"index.jsp\"> Sign in again <a>!</h2></font>");
		}
		// If the user's login is unsuccessful
		else if (login.changePassword() == 0) {
			out.println("<font color=\"#cc0000\"><h2>Incorrect username(email) or password!</h2></font>"); 	  
		}
		//If changing a password is unsuccessful
		else {
			out.println("<font color=\"#cc0000\"><h2>Password change has failed. Please try it again!</h2></font>");
		}
	}
	%>

</body>
</html>
