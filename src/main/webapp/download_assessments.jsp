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

<title>Download Assessments</title>
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

	//check the role of the user who downloads assessments.
	// Assessments can be downloaded by nlic (reviewed assessments) or by pr (original assessments)
	// access to assessments by dh and lt is handled by check_assessment.jsp
	String role = request.getParameter("role");

	String user = session.getAttribute("login").toString();
	String sqlquery = "";
	//query is different depending on the role
	// if the user is pr, he/she needs to know which units he/she is assigned as a reviewer
	// if the user is nlic, he/she needs to know which units to be reviewed he/she is assigned as the NLiC
	switch (role) {
	case "pr": sqlquery = "SELECT * FROM units WHERE 2boffered=1 AND 2breviewed=1 AND reviewer1='" + user + 
								"' OR reviewer2='"+ user + "' OR reviewer3='" + user + "' ORDER BY code ASC"; break;
	case "nlic": sqlquery = "SELECT * FROM units WHERE 2boffered=1 AND 2breviewed=1 AND nlic='" + user + "' ORDER BY code ASC";
	}

	// Copy assessments from database to file system and make them downloadable
	// Sprint 5 is to complete this method
	workflow.downloadAssessment(request, sqlquery);

	DBResult dbr = workflow.getUnits(sqlquery);

	Connection conn = dbr.getCONN();
	PreparedStatement ps = dbr.getPS();
	ResultSet rs = dbr.getRS();
	
	// if no unit is retrieved
	if (!rs.next()) {
		out.print("<font color=\"#cc0000\"><h1>Nothing to download!<h1></font>");
		out.print("<a href=\"" + role + ".jsp\"><button type=\"submit\" id=\"backtohome\"> " +
						"<i class=\"fa fa-home\"></i> Back to Home</button></a>");
		
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
		<h2>Download Assessments</h2>
		<form method="post">
			<table>
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
					String[] at_feedback = {"at1_feedback", "at2_feedback", "at3_feedback"}; //feedback provided by lt or dh after checking
					String[] at_type = {"at1_type", "at2_type", "at3_type" };
					String[] reviewer1_at = {"reviewer1_at1", "reviewer1_at2", "reviewer1_at3"};
					String[] reviewer2_at = {"reviewer2_at1", "reviewer2_at2", "reviewer2_at3"};
					String[] reviewer3_at = {"reviewer3_at1", "reviewer3_at2", "reviewer3_at3"};

					while (rs.next()) {
						String code = rs.getString("code");

						out.print("<tr>");
						out.print("<td>" + rs.getString("discipline") + "</td>");
						out.print("<td>" + code + "</td>");
						out.print("<td>" + rs.getString("name") + "</td>");
						
						//each unit has 3 assessments, check one by one
						for (int i = 0; i < 3; i++) {
							String at_id = code + "_" + at_label[i]; // this is used as the assessment file name
							String status = rs.getString(at_status[i]);
							
							if (status != null) { 
								String type = rs.getString(at_type[i]); 
								// if the assessment has not been reviewed by this particular pr -- download the assessment for review
								if (role.equals("pr") && !status.equals("reviewed") 
										&& (status.equals("ready")
										|| (status.startsWith("reviewer") // (status.startsWith("reviewer") && ... ) was added
										&& !status.equals(workflow.whichReviewer(request, session, rs))))) {
									out.print("<td class=\"clickable\"><a href =\"" + at_id + type + "\" >Download " + at_label[i] + "<a></td>"); // class=\"clickable\" was added on 4May2022
								}
								// if the assessment is returned by lt or dh -- nlic retrieves feedback 
								else if ((role.equals("nlic") && status.equals("lt_returned"))
											|| (role.equals("nlic") && status.equals("dh_returned"))) {
									out.print("<td class=\"viewable\">" + rs.getString(at_feedback[i]) + "</td>"); // class=\"viewable\" was added on 4May2022
								}
								// if the assessment has been reviewed by all assigned reviewers -- nlic downloads all reviews
								else if (role.equals("nlic") && status.equals("reviewed")) {
									out.print("<td class=\"clickable\">"); // class=\"clickable\" was added on 4May2022
									if (rs.getString("reviewer1") != null && rs.getString(reviewer1_at[i]) != null) {
										out.print("<a href=\"" + at_id + "_r1" + type + "\" target=\"_blank\">Download " + at_label[i] + " (Reviewer 1)<a><br>"); // target="_blank": Opens the document in a new window or tab
									}
									if (rs.getString("reviewer2") != null && rs.getString(reviewer2_at[i]) != null) {
										out.print("<a href=\"" + at_id + "_r2" + type + "\" target=\"_blank\">Download " + at_label[i] + " (Reviewer 2)<a><br>");
									}
									if (rs.getString("reviewer3") != null && rs.getString(reviewer3_at[i]) != null) {
										out.print("<a href=\"" + at_id + "_r3" + type + "\" target=\"_blank\">Download " + at_label[i] + " (Reviewer 3)<a><br>");
									}
									out.print("</td>");
								}
								else {
									out.print("<td class=\"caution\">Nothing to download</td>");
								}
							}
							else {
								out.print("<td class=\"caution\">Nothing to download</td>");
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
