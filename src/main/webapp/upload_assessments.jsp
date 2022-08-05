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

<title>Upload Original or Revised Assessments</title>

<script>
    function showProgress() {
        document.getElementById('progress').style.display = 'inline-block';
    }
    
    
</script>

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

	// check the role of the user who uploads assessments.
	// Assessments can be uploaded by nlic (original/revised assessments) or by pr (reviewed assessments)
	// dh and lt do not upload assessments
	String role = request.getParameter("role");
	
	String user = session.getAttribute("login").toString();
	String sqlquery = "";
	// query is different depending on the role
	// if the user is pr, he/she needs to know which units he/she is assigned as a reviewer
	// if the user is nlic, he/she needs to know which units to be reviewed he/she is assigned as the NLiC
	switch (role) {
	case "pr": sqlquery = "SELECT * FROM units WHERE 2boffered=1 AND 2breviewed=1 AND reviewer1='" + user + 
								"' OR reviewer2='" + user + "' OR reviewer3='" + user + "' ORDER BY code ASC"; break;
	case "nlic": sqlquery = "SELECT * FROM units WHERE 2boffered=1 AND 2breviewed=1 AND nlic='" + user + "' ORDER BY code ASC";
	}

	DBResult dbr = workflow.getUnits(sqlquery);

	Connection conn = dbr.getCONN();
	PreparedStatement ps = dbr.getPS();
	ResultSet rs = dbr.getRS();
	
	// if no unit is retrieved
	if (!rs.next()) {
		out.print("<font color=\"#cc0000\"><h1>Nothing to upload!<h1></font>");
		out.print("<a href=\"" + role + ".jsp\"><button type=\"submit\" id=\"backtohome\"><i class=\"fa fa-home\"></i> Back to Home</button></a>");
		
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
		<h2>Upload Assessments</h2>
		<form action="show_assessments.jsp" method="post" onsubmit="btn_confirm.disabled = true; return true;" enctype="multipart/form-data">
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
					/* Each assessment may be in one of the following status after upload:
					 1. uploaded: original assessment uploaded by NLiC
					 2. lt_returned: returned to NLiC via L&T screening due to compliance issues before review
					 3. dh_returned: returned to NLiC via DH checking due to issues after review and revision
					 4. ready: ready for review marked by L&T
					 5. reviewed: reviewed by all reviewers (reviewed) or by some of them (reviewer1/reviewer2/reviewer3)
					 6. revised: revised by NLiC by addressing review comments
					 7. approved: approved by DH for publishing */
					 
					// if there is nothing to upload, do not show the submit button
					Boolean uploadable = false;

					int row = 0;
					while (rs.next()) {
						// each row is a unit, which has three assessments
						// at_no is used to identify each unique unit_assessment
						String[] at_no = {Integer.toString(row) + "_1", Integer.toString(row) + "_2", Integer.toString(row) + "_3"};
						

						out.print("<tr>");
						out.print("<td>" + rs.getString("discipline") + "</td>");
						out.print("<td>" + rs.getString("code") + "</td>");
						out.print("<td>" + rs.getString("name") + "</td>");

						//each unit has 3 assessments, check one by one
						for (int i = 0; i < 3; i++) {
							String status = rs.getString(at_status[i]);
							//original assessment not uploaded yet - to uploaded by NLiC
							if (role.equals("nlic") && rs.getString(at_status[i]) == null) {
								out.print("<td class=\"clickable\">Upload <b>Original</b> Assessment<br><input type=\"file\" class=\"upload_file\" name=\"" + at_no[i] + "\"/> " + // class=\"clickable\" and class=\"upload_file\" were added on 4May2022
											"<input type=\"hidden\" name=\"" + at_no[i] + "\" value=\"uploaded\"/></td>"); // the status will be "uploaded" (NOT SHOWN IN THE TABLE)
								uploadable = true;
							}
							else if (rs.getString(at_status[i]) != null) {
								//assessment returned by L&T after checking - to be fixed and re-uploaded by NLiC
								if (role.equals("nlic") && rs.getString(at_status[i]).equals("lt_returned")) {
									out.print("<td class=\"clickable\">Upload <b>Screened</b> Assessmen<br>" + // class=\"clickable\" was added on 4May2022
												"<input type=\"file\" class=\"upload_file\" name=\"" + at_no[i] + "\"/><input type=\"hidden\" name=\"" + at_no[i] + "\" value=\"uploaded\"/></td> "); // class=\"upload_file\" was added on 4May2022
									uploadable = true;
								}
								//assessment reviewed by all reviewers or checked and returned by DH - to be revised by NLiC
								else if (role.equals("nlic") && (rs.getString(at_status[i]).equals("reviewed")
											|| rs.getString(at_status[i]).equals("dh_returned"))) {
									out.print("<td class=\"clickable\">Upload <b>Revised</b> Assessment<br>" + // class=\"clickable\" was added on 4May2022
												"<input type=\"file\" class=\"upload_file\" name=\"" + at_no[i] + "\"/><input type=\"hidden\" name=\"" + at_no[i] + "\" value=\"revised\"/></td> "); // class=\"upload_file\" was added on 4May2022
									uploadable = true;
								}
								//assessment not reviewed by this reviewer yet (may or may not have been reviewed by other reviewers) 
								// - to be reviewed by this reviewer
								else if (role.equals("pr") && !rs.getString(at_status[i]).equals("reviewed")
											&& (rs.getString(at_status[i]).equals("ready")
											|| (status.startsWith("reviewer") // (status.startsWith("reviewer") && ... ) was added
											&& !rs.getString(at_status[i]).equals(workflow.whichReviewer(request, session, rs))))) {
									String reviewer = workflow.whichReviewer(request, session, rs);
									
									out.print("<td class=\"clickable\">Upload <b>Reviewed</b> Assessment<br>" + // class=\"clickable\" was added on 4May2022
												"<input type=\"file\" class=\"upload_file\" name=\"" + at_no[i] + "\"/><input type=\"hidden\" name=\"" + at_no[i] + "\" value=\"" + reviewer + "\"/></td> "); // class=\"upload_file\" was added on 4May2022
									uploadable = true;
								}
								else {
									out.print("<td class=\"caution\">Nothing to upload</td> ");
								}
							}
							else {
								out.print("<td class=\"caution\">Nothing to upload</td> ");
							}
						}

						out.print("</tr>");
						row++;
					}
					
					rs.close();
					ps.close();
					conn.close();
					
					%>
					
				</tbody>
			</table>
			
					<%
					// return to either nlic.jsp or pr.jsp depending on the role
					// there is at least one upload
					if (uploadable) {
						// This is the original upload button
						out.print("<input type=\"submit\" class=\"btn_upload\" id=\"btn_submit\""
								+ "value=\"Upload\" formaction=\"show_assessments.jsp\" onclick=\"showProgress()\">" // onclick=\"showProgress()\"   does not work
								+ "<input type=\"hidden\" name=\"role\" value =" + role + ">");
						out.print("<i id=\"progress\" class=\"fa fa-spinner fa-spin\" style=\"display:none\"></i>"); // ADDED on 19Apr2022
					}
					%>

		</form>
		<a href="home.jsp"><button type="submit" id="backtohome"><i class="fa fa-home"></i> Back to Home</button></a>
	</div>
</body>
</html>