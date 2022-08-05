<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ page import="java.sql.*, com.beanlib.DBResult, com.beanlib.Workflow" %>
<%@ page errorPage="error.jsp" %>
<jsp:useBean id="workflow" class="com.beanlib.Workflow"></jsp:useBean>

<!DOCTYPE html>
<html>
<head>
<meta charset="UTF-8" name="viewport" content="width=device-width, initial-scale=1">
<link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/4.7.0/css/font-awesome.min.css">
<link rel="stylesheet" href="${pageContext.request.contextPath}/css/styles.css">

<script> /* ADDED on 21Apr2022 */
    function showProgress() {
        document.getElementById('progress').style.display = 'inline-block';
    }
</script>

<title>Allocate NLiCs and Peer Reviewers</title>

</head>

<body>
	<header>
		<h1>Peer Review of Assessment Workflow System</h1>
	</header>
	
	<%
	// If the user has not logged in, the unauthorised user needs to log in first
	if (session.getAttribute("login") == null || session.getAttribute("login") == " ") {
		response.sendRedirect("index.jsp");
		return;
	}

	//retrieve all units to be peer reviewed for the login user's discipline
	String sqlquery = "SELECT * FROM units WHERE 2boffered=1 AND 2breviewed=1 AND discipline=\'" + 
						workflow.getDiscipline(session.getAttribute("login").toString()) + "\'"; // NEEDED for SPRINT 2
			
	DBResult dbr = workflow.getUnits(sqlquery);
	Connection conn = dbr.getCONN();
	
	PreparedStatement ps = dbr.getPS();
	ResultSet rs = dbr.getRS();
 	
	//if L&T liason has not nominated any unit for the discipline
	if (!rs.next()) {
		out.print("<font color=\"cc0000\"><h1>You have no task!<h1></font>");
		out.print("<a href=\"dh.jsp\"><button type=\"submit\" id=\"backtohome\"> " +
						"<i class=\"fa fa-home\"></i> Back to Home</button></a>");
		
		rs.close();
		ps.close();
		conn.close();
		
		return;
	} 
	//if DH has already allocated stakeholders
	else if (rs.getString("nlic") != null && (rs.getString("reviewer1") != null 
				|| rs.getString("reviewer2") != null || rs.getString("reviewer3") != null)) {
		out.print("<font color=\"#3c1a50\"><h1>You have already allocated NLiCs and reviewers!<h1></font>");
		out.print("<a href=\"dh.jsp\"><button type=\"submit\" id=\"backtohome\"><i class=\"fa fa-home\"></i> Back to Home</button></a>");
		
		rs.close();
		ps.close();
		conn.close();
		
		return;
	} 
	// DH needs to allocate stakeholders
	else {
		rs.close();
		ps.close();
		conn.close();
	}
	%>

	<div class="container">
		<h2>You Must Allocate All NLiCs and Reviewers in Your Discipline</h2>
		<h2>Enter Their Email Addresses</h2>
		<form method="post" action="show_stakeholders.jsp" onsubmit="disable_btn.disabled = true; return true;"> <!-- onsubmit="btn_comfirm.disabled = true; return true; -->
			<table class="table table-bordered table-striped">
				<thead>
					<tr>
						<th>Unit Code</th>
						<th>Unit Title</th>
						<th>NLiC's Email Address</th>
						<th>Reviewers' Email Addresses</th>
					</tr>
				</thead>
				<tbody>
					<% 
					// get the login user's discipline
					String disc = workflow.getDiscipline(session.getAttribute("login").toString());
					// retrieve all units to be peer reviewed for the login user's discipline
					sqlquery = "SELECT * FROM units WHERE 2boffered=1 AND 2breviewed=1 AND discipline = '" + disc + "' ORDER BY code ASC";
							
					dbr = workflow.getUnits(sqlquery);

					conn = dbr.getCONN();
					ps = dbr.getPS();
					rs = dbr.getRS();

					while (rs.next()) {
						out.print("<tr>");
						out.print("<td>" + rs.getString("code") + "</td>");
						out.print("<td>" + rs.getString("name") + "</td>");
						// input for the NLiC of the unit
						out.print("<td class=\"clickable\" ><input type=\"text\" name=\"nlic\" placeholder=\"Required\" required></td>");
						// input for at least one reviewer and up to three reviewers
						out.print("<td class=\"clickable\" ><input type=\"text\" name=\"reviewer1\" placeholder=\"Required\" required><br>" + 
									"<input type=\"text\" name=\"reviewer2\"><br>" + 
									"<input type=\"text\" name=\"reviewer3\"></td>");
						out.print("</tr>");
					}
					
					rs.close();
					ps.close();
					conn.close();
					%>
			</table>
			<button type="submit" id="btn_submit" onclick="showProgress()"> Submit</button> 
																							
			<i id="progress" class="fa fa-spinner fa-spin" style="display:none"></i> 
		</form>
		<br>
		<a href="dh.jsp"><button type="submit" id="backtohome"><i class="fa fa-home"></i> Cancel</button></a>
	</div>
</body>
</html>
