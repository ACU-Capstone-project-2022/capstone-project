<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ page import="java.sql.*, com.beanlib.*" %>
<%@ page errorPage="error.jsp" %>
<jsp:useBean id="login" class="com.beanlib.Authentication"></jsp:useBean>
<jsp:useBean id="workflow" class="com.beanlib.Workflow"></jsp:useBean>
<jsp:useBean id="util" class="com.beanlib.PRoAUtil"></jsp:useBean>

<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8" name="viewport" content="width=device-width, initial-scale=1">
<link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/4.7.0/css/font-awesome.min.css">
<link rel="stylesheet" href="${pageContext.request.contextPath}/css/styles.css">

<title>List of Units for Review</title>
</head>

<body>
	<header>
		<h1>Peer Review of Assessment Workflow System</h1>
		<h2>Nominated Units to be Peer Reviewed</h2>
	</header>

	<div class="container">
		<%
		// check if the client is authorised or not, if not, the user needs to log in first
		if (session.getAttribute("login") == null || session.getAttribute("login") == " ") {
			response.sendRedirect("index.jsp");
			return;
		}
		// offered[] contains the row numbers of units selected to be offered
		String[] offered = request.getParameterValues("2boffered");
		// reviewed[] contains the row numbers of units selected to be reviewed
		// reviewed[] is a subset of offered: if a unit is not offered, it certainly won't be reviewed
		String[] reviewed = request.getParameterValues("2breviewed");

		// Test if the user has not selected any unit for review
		if (offered == null || reviewed == null) {
			out.print("<h3><font color=\"#cc0000\">You have not nominated any unit for review!</font></h3>");
			out.print("<a href=\"lt.jsp\"><button type=\"submit\" id=\"backtohome\"><i class=\"fa fa-home\"></i> Back to Home</button></a>");
			return;
		}
		// If units have been selected	 
		else {
			// setReviewedUnits(offered, reviewed) method sets the offered units to be reviewed and returns DHs' email addresses
			// Sprint 1 is to complete the setReviewdUnits method in Workflow.java
			String[] emailto = workflow.setReviewedUnits(offered, reviewed);
			// Learning & Teaching Officer informs DHs of allocating stakeholders via email
			if (emailto.length > 0) {
				// extract the url of this request
				String linkbase = request.getRequestURL().toString();
				String link = linkbase.substring(0, linkbase.indexOf("show_units4review.jsp"));
				
				String emailsub = "PRoAWorkflow: Action Required from Discipline Head";
				String emailmsg = "The Learning & Teaching Officer has nominated units under your discipline for peer revivew. " +
								  "Please click <a href=\"" + link + "\"> this link </a> to Sign in as a Discipline Head " +
								  "and then Allocate Stakeholders to Units";
				// Send out an email to inform the responsible DHs to allocate reviewers
				util.sendEmail(emailto, emailsub, emailmsg);
				
				String webmsg = "The responsible discipline heads have been informed to allocate reviewers!";
				out.print("<h3><font color=\"#3c1a50\">" + webmsg + "</font></h3>");
			}
			else {
				out.print("<h3><font color=\"#cc0000\">Something is wrong!</font></h3>");
				out.print("<a href=\"lt.jsp\"><button type=\"submit\"><i class=\"fa fa-home\"></i> Back to Home</button></a>");
				return;
			}
		}
		%>
		
		<form method="post">
			<table class="table table-bordered table-striped">
				<thead>
					<tr>
						<th>Discipline</th>
						<th>Unit Code</th>
						<th>Unit Title</th>
					</tr>
				</thead>
				<tbody>
					<%
					// retrieve and display all selectd units for review from the database
					String sqlquery = "SELECT * FROM units WHERE 2boffered=1 AND 2breviewed=1 ORDER BY discipline ASC, code ASC";
							
					DBResult dbr = workflow.getUnits(sqlquery);

					Connection conn = dbr.getCONN();
					PreparedStatement ps = dbr.getPS();
					ResultSet rs = dbr.getRS();
					
					while (rs.next()) {
						out.print("<tr>");
						out.print("<td>" + rs.getString("discipline") + "</td>");
						out.print("<td>" + rs.getString("code") + "</td>");
						out.print("<td>" + rs.getString("name") + "</td>");
						out.print("</tr>");
					}
					
					rs.close();
					ps.close();
					conn.close();
					%>
				</tbody>
			</table>
		</form>
		<a href="lt.jsp"><button id="backtohome"><i class="fa fa-home"></i> Back to Home</button></a>
	</div>
</body>
</html>
