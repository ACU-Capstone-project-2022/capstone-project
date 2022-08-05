<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="java.sql.*, com.beanlib.DBResult, com.beanlib.Workflow"%>
<%@ page errorPage="error.jsp" %>
<jsp:useBean id="workflow" class="com.beanlib.Workflow"></jsp:useBean>

<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8" name="viewport" content="width=device-width, initial-scale=1">
<link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/4.7.0/css/font-awesome.min.css">
<link rel="stylesheet" href="${pageContext.request.contextPath}/css/styles.css">
<link rel="stylesheet" href="https://fonts.googleapis.com/icon?family=Material+Icons">

<script>
    function showProgress() {
        document.getElementById('progress').style.display = 'inline-block';
    }
</script>

<title>Send Out Assessments for Peer Review</title>
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
	// checking done by either LT or DH
	String role = request.getParameter("role");
	// status of an assessment
	/* Each assessment may be in one of the following status after upload:
	 1. uploaded: original assessment uploaded by NLiC
	 2. lt_returned: returned to NLiC via L&T screening due to compliance issues before review
	 3. dh_returned: returned to NLiC via DH checking due to issues after review and revision
	 4. ready: ready for review marked by L&T
	 5. reviewed: reviewed by all reviewers (reviewed) or by some of them (reviewer1/reviewer2/reviewer3)
	 6. revised: revised by NLiC by addressing review comments
	 7. approved: approved by DH for publishing */
	String status = "";
	// lt only checks assessments with an "uploaded" status 
	// dh only checks assessments with a "revised" status
	if (role.equals("lt")) { // If the user log in as a Learning & Teaching Officer, the status is "uploaded"
		status = "uploaded";
	} 
	else if (role.equals("dh")) { // If the user log in as a Discipline Head, the status is "revised"
		status = "revised";
	}

	String sqlquery = "SELECT * FROM units WHERE (2boffered=1) AND (2breviewed=1)" + 
						" AND (at1_status = \"" + status + "\"" + 
						" OR at2_status = \"" + status + "\"" + 
						" OR at3_status = \"" + status + "\")" + 
						" ORDER BY discipline ASC, code ASC";

	// Copy assessments from database to file system and make them downloadable
	// Sprint 5 is to complete this method
	workflow.downloadAssessment(request, sqlquery);

	DBResult dbr = workflow.getUnits(sqlquery);
	
	Connection conn = dbr.getCONN();
	PreparedStatement ps = dbr.getPS();
	ResultSet rs = dbr.getRS();
	
	// if no unit is retrieved
	if (!rs.next()) {
		out.print("<font color=\"#3c1a50\"><h1>There is no unit to be checked, or you have finished checking compliance of assessments.<h1></font>");
		out.print("<a href = \"" + role + ".jsp\"><button type=\"submit\" id=\"backtohome\"> " +
						"<i class=\"fa fa-home\"></i> Back to Home</button></a>");
		
		rs.close();
		ps.close();
		conn.close();
		
		return;
		}
	%>

	<div class="container">
		<h2>Check the Following Units one by one</h2>
		<form action="process_assessments.jsp" method="post" onsubmit="btn_confirm.disabled = true; return true;"> <!-- onsubmit="showAlert()" -->
			<table class="table table-bordered table-striped">
				<thead>
					<tr>
						<th>Discipline</th>
						<th>Unit Code</th>
						<th>Unit Title</th>
						<th>NLiC</th>
					</tr>
				</thead>
				<tbody>
					<tr>
						<td><%=rs.getString("discipline")%></td>
						<td><%=rs.getString("code")%></td>
						<td><%=rs.getString("name")%></td>
						<td><%=rs.getString("nlic")%></td>
					</tr>
				</tbody>
			</table>

			<table class="table table-bordered table-striped">
				<%
				String[] at_label = {"at1", "at2", "at3"};
				String[] at_status = {"at1_status", "at2_status", "at3_status"};
				String[] at_type = {"at1_type", "at2_type", "at3_type"};
				String at_id = ""; // this is used as the assessment file name
				String code = rs.getString("code");
				
				// Assessment download links and two options: (1) return to nlic with comments (2) pass the check
				// One unit per page, check three assessments one by one 		
				for (int i = 0; i < 3; i++) {
					if (rs.getString(at_status[i]) != null) {
						String type = rs.getString(at_type[i]);
						// lt only checkes assessments with an "uploaded" status 
						// dh only checkes assessments with a "revised" status
						if ((role.equals("lt") && rs.getString(at_status[i]).equals("uploaded"))
							|| (role.equals("dh") && rs.getString(at_status[i]).equals("revised"))) {
							at_id = code + "_" + at_label[i]; // file name for the downloaded assessment
							out.print("<tr>");
							out.print("<td class=\"clickable\"><a href =\"" + at_id + type + "\" target=\"_blank\">Download " + at_label[i] + "<a></td>"); // class=\"clickable\" was added on 4May2022,  target=\"_blank\" was added on 8May2022
							// two options: (1) return to NLiC with feedback (2) pass the checking		
							out.print("<td class=\"clickable\" onclick=\"getElementById('return_" + i + "').click();\"><input type=\"radio\" id=\"return_" + i + "\" name=\"choice_" + i + "\" value=\"return\">" + // class=\"clickable\" was added on 4May2022
										"<label for=\"return\">Return to NLiC&nbsp;&nbsp;&nbsp;&nbsp;</label>" + 
										"<textarea minlength=\"50\" maxlength=\"200\" name=\"feedback_" + i +
										"\" placeholder=\"Give Feedback Here (at least 50 characters)\" rows=\"4\" cols=\"50\"></textarea></td>");
									out.print("<td class=\"clickable\" onclick=\"getElementById('pass_" + i + "').click();\"><input type=\"radio\" id=\"pass_" + i + "\" name=\"choice_" + i + "\" value=\"pass\" checked>" + // class=\"clickable\" was added on 4May2022
										"<label for=\"pass\">Pass the check</label></td>");
						}
					}
				}

				rs.close();
				ps.close();
				conn.close();
				%>
			</table>

			<input type="submit" class="btn_upload" id="btn_submit" value="Next"
					formaction="process_assessments.jsp" onclick="showProgress()">
			<input type="hidden" name="code" value=<%= code %>> 
			<input type="hidden" name="role" value=<%= role %>>
			<i id="progress" class="fa fa-spinner fa-spin" style="display:none"></i> 
		</form>
		<br>
		<a href="<%= role %>.jsp"><button type="submit" id="backtohome"><i class="fa fa-home"></i> Cancel</button></a>
	</div>

</body>
</html>
