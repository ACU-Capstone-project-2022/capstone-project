<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ page import="java.util.*, com.beanlib.Authentication" %> 
<%@ page errorPage="error.jsp" %>
<jsp:useBean id="login" class="com.beanlib.Authentication"></jsp:useBean>
<jsp:useBean id="conf" class="com.beanlib.Configuration"></jsp:useBean>
<jsp:useBean id="util" class="com.beanlib.PRoAUtil"></jsp:useBean>

<!DOCTYPE html>
<html>
<head>
<meta charset="UTF-8" name="viewport" content="width=device-width, initial-scale=1">
<link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/4.7.0/css/font-awesome.min.css">
<link rel="stylesheet" href="${pageContext.request.contextPath}/css/styles.css">

<script>
    function showProgress() {
        document.getElementById('progress').style.display = 'inline-block';
    }
</script>

<title>Please Sign Up Here</title>
</head>

<body>
	<header>
		<h1>Peer Review of Assessment Workflow System</h1>
		<h2>Sign Up</h2>
	</header>
	
	<form method="post">
		<div class="container">
			<label for="firstname">First name:</label>
			<input type="text" placeholder="First name" name="firstname" id="firstname" required> 
			<label for="lastname">Last name: </label>
			<input type="text" placeholder="Last name" name="lastname" id="lastname"required>
			<label for ="email">Email: </label>
			<input type="text" placeholder="Email" name="email" id="email" required>
			<label for="password">Password: </label>
			<input type="password" placeholder="Password" name="password" id="password" required>
					
			<label for="discipline">Choose your discipline:</label>
			<select id="discipline" name="discipline"  class="discipline" required>
				<option value="NA">No Discipline</option>
				<option value="MMkt">Managing Markets</option>
				<option value="MMon">Managing Money</option>
				<option value="MPO">Managing People and Organisations</option>
				<option value="WWT">Working with Technology</option>
			</select>
			
			<br><br>
			
			<fieldset> <!-- Defines a form control group -->
				<legend>Your Role(s)</legend>
				<input type="checkbox" name="roles" value="nlic" id="nlic"><label for="nlic">National Lecturer in Charge</label><br>
				<input type="checkbox" name="roles" value="pr" id="pr"><label for="pr">Peer Reviewer</label><br>
				<input type="checkbox" name="roles" value="dh" id="dh"><label for="dh">Discipline Head</label><br>
				<input type="checkbox" name="roles" value="lt" id="lt"><label for="lt">Learning and Teaching Officer</label><br>
			</fieldset>
			
			<br><br>
			
			<button type="submit" name="btn_register" id="btn_submit" onclick="showProgress()">Register</button>
			<i id="progress" class="fa fa-spinner fa-spin" style="display:none"></i> <!-- ADDED on 19Apr2022 -->
		</div>
	</form>

	<form method="post" action="index.jsp">
		<div class="container">
			<label for="btn_sign_up_or_sign_in">Ready to Sign In? </label>
			<button type="submit" id="btn_sign_up_or_sign_in">Sign In Here</button>
		</div>
	</form>

	<%
	String roles = "";
	// Test if the client has already logged in
	if (session.getAttribute("login") != null) {
		response.sendRedirect("home.jsp");
	} 
	else {
		// if register button is clicked // 
		if (request.getParameter("btn_register") != null) {
			// return all checkbox selections 
			String[] selectedRoles = request.getParameterValues("roles");
			// concatenate array of strings into a single string seperated by ','
			if (selectedRoles != null) {
				for (String sr : selectedRoles) {
					roles += sr + ",";
					}
				if (roles.length() > 0) {
					roles = roles.substring(0, roles.length() - 1);
				}
			}
		}
	}
	%>
	
	<!-- pass all user input to login Bean class -->
	<jsp:setProperty name="login" property="firstname" param="firstname" />
	<jsp:setProperty name="login" property="lastname" param="lastname" />
	<jsp:setProperty name="login" property="email" param="email" />
	<jsp:setProperty name="login" property="password" param="password" />
 	<jsp:setProperty name="login" property="discipline" param="discipline" />
	<jsp:setProperty name="login" property="roles" value="<%= roles %>" /> 
	
	<%
	// if register button is clicked
	if (request.getParameter("btn_register") != null) {
		// register successful 
		if (login.registerLogin() == 1) {
			// send email notification to approver
			String firstname = request.getParameter("firstname");
			String lastname = request.getParameter("lastname");
			String discipline = request.getParameter("discipline");
			String email = request.getParameter("email");
			String approvEmail = conf.getApprovEmail();
			String[] approver = {approvEmail};
			
			// Extract the URL of the request
			String linkbase = request.getRequestURL().toString();
			String link = linkbase.substring(0, linkbase.indexOf("register.jsp"));
						
			String subject = "PRoAWorkflow: Accout Registration Approval Required";
			String htmlmsg = firstname + " " + lastname + " from " + discipline + " discipline requested creating account: "
							+ email + " with roles of " + roles + ".<br>" + " Please <a href=\"" + link + "checkrego.jsp?email="
							+ email + "&decision=yes\"> Approve </a> or " + "<a href=\"" + link + "checkrego.jsp?email=" + email
							+ "&decision=no\"> Decline </a>";

			util.sendEmail(approver, subject, htmlmsg);

			out.println("<font color=\"#3c1a50\"><h2>Registration is successful, pending approval!</h2></font>");
		}
		// If the username has already registered
		else if (login.registerLogin() == 0) {
			out.println("<font color=\"#cc0000\"><h2>This account was already registered. " + 
						" Please <a href = \"index.jsp\"> log in <a>!</h2></font>");
		}
		// If the registeration is unccessful
		else {
			out.println("<font color=\"#cc0000\"><h2>Register is unsuccessful. Please try it again!</h2></font>");
		}
	}
	%>

</body>
</html>
