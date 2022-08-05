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

<title>Show Approved Assessments</title>
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

	String stakeholder = "nlic";
	String user = session.getAttribute("login").toString();

	String sqlquery = "SELECT * FROM units WHERE 2boffered=1 AND 2breviewed=1 AND " + stakeholder + "='" + user + "' ORDER BY code ASC";

	DBResult dbr = workflow.getUnits(sqlquery);

	Connection conn = dbr.getCONN();
	PreparedStatement ps = dbr.getPS();
	ResultSet rs = dbr.getRS();

	if (!rs.next()) {
		out.print("<h1 class=\"caution\">Nothing to download!<h1>");
		out.print("<a href=\"nlic.jsp\"><button type=\"submit\" id=\"backtohome\"> " +
						"<i class=\"fa fa-home\"></i>Back to Home</button></a>");
		
		rs.close();
		ps.close();
		conn.close();
		
		return;
	}
	else {
		rs.close();
		ps.close();
		conn.close();
	}
	%>

	<div class="container">
		<h2>Show Approved Assessments</h2>
		<form method="post">
			<table class="table table-bordered table-striped">
				<thead>
					<tr>
						<th>Discipline</th>
						<th>Unit Code</th>
						<th>Unit Title</th>
						<th>Assessment 1</th>
						<th>Assessment 2</th>
						<th>Assessment 3</th>
					</tr>
				</thead>
				<tbody>
					<%
					dbr = workflow.getUnits(sqlquery);

					conn = dbr.getCONN();
					ps = dbr.getPS();
					rs = dbr.getRS();

					String[] at_label = {"at1", "at2", "at3"};
					String[] at_status = {"at1_status", "at2_status", "at3_status"};
					String[] at_type = {"at1_type", "at2_type", "at3_type"};

					/* Each assessment may be in one of the following status after upload:
					1. uploaded: uploaded original assessment by NLiC
					2. lt_returned: returned to NLiC via L&T screening due to compliance issues
					3. dh_returned: returned to NLiC via DH checking due to issues
					4. ready: ready for review marked by L&T
					5. reviewed: reviewed by PR/DH
					6. revised: revised by NLiC by addressing review comments
					7. approved: approved by DH for publishing
					*/

					while (rs.next()) {
						String code = rs.getString("code");

						out.print("<tr>");
						out.print("<td>" + rs.getString("discipline") + "</td>");
						out.print("<td>" + code + "</td>");
						out.print("<td>" + rs.getString("name") + "</td>");

						for (int i = 0; i < 3; i++) {
							String at_id = code + "_" + at_label[i];
							if (rs.getString(at_status[i]) != null && rs.getString(at_status[i]).equals("approved")) {
								String type = rs.getString(at_type[i]);
								out.print("<td class=\"clickable\"><font color=\"#00ff00\"><a href =\"" + at_id + type + "\" target=\"_blank\">" +  // class=\"clickable\" was added on 4May2022,  target=\"_blank\" was added on 8May2022
											"Approved for publishing</font></a></td>");
							}
							else {
								out.print("<td class=\"caution\">Not yet approved</td>");
							}
						}
						out.print("</tr>");
					}

					rs.close();
					ps.close();
					conn.close();

					%>
 				</tbody>
			</table>
		</form>
		<a href="home.jsp"><button type="submit" id="backtohome"><i class="fa fa-home"></i> Back to Home</button></a>
	</div>
</body>
</html>
