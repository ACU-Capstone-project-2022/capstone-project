<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ page import="java.sql.*, com.beanlib.*" %>
<%@ page errorPage="error.jsp" %>
<jsp:useBean id="login" class="com.beanlib.Authentication"></jsp:useBean>
<jsp:useBean id="workflow" class="com.beanlib.Workflow"></jsp:useBean>
<jsp:useBean id="util" class="com.beanlib.PRoAUtil"></jsp:useBean>

<!DOCTYPE html>
<html>
<head>
<meta charset="UTF-8" name="viewport" content="width=device-width, initial-scale=1">
<link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/4.7.0/css/font-awesome.min.css">
<link rel="stylesheet" href="${pageContext.request.contextPath}/css/styles.css">

<title>Uploaded Assessments</title>
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
	String loginrole = String.valueOf(session.getAttribute("loginrole")); 
		
	String user = session.getAttribute("login").toString();
	String sqlQuery = "";
	// query is different depending on the role
	// if the user is pr, he/she needs to know which units he/she is assigned as a reviewer
	// if the user is nlic, he/she needs to know which units for review he/she is assigned as the NLiC
	switch (loginrole) { // CHANGED FROM "role", then the error's gone
		case "pr": sqlQuery = "SELECT * FROM units WHERE 2boffered=1 AND 2breviewed=1 AND reviewer1='" + user + 
							"' OR reviewer2='" + user + "' OR reviewer3='" + user + "' ORDER BY code ASC"; break;
		case "nlic": sqlQuery = "SELECT * FROM units WHERE 2boffered=1 AND 2breviewed=1 AND nlic='" + user + "' ORDER BY code ASC";
	}
	
		
	// message to be displayed
	String webmsg = "";
	// Extract the base url of the request
	String linkbase = request.getRequestURL().toString();
	String link = linkbase.substring(0, linkbase.indexOf("show_assessments.jsp"));

	/* -1: upload unsuccessful
	 *  0: only uploaded by nlic
	 *  1: only revised by nlic
	 *  2: mix of uploaded and revised by nlic
	 *  3: reviewed by pr */
 	switch (workflow.uploadAssessments(request, sqlQuery)) { 
	case 3: // reviewed by pr
		// email relevant NLiCs - reviewed by pr
		String[] emailto = workflow.getEmailAddresses(sqlQuery, "nlic");
		String emailsub = "PRoAWorkflow: Action Required from National Lecturer in Charge";
		String emailmsg = "Your assessments have been reviewed. Please click <a href=\"" + link + "\"> this link </a> " + 
					"to Sign in as a National Lecturer in Charge and then View Checked/Reviewed Assessments.";
		util.sendEmail(emailto, emailsub, emailmsg);
		
		webmsg = "The NLiCs have been informed to view reviewed assessments!";
		out.print("<h2><font color=\"#3c1a50\">" + webmsg + "</font></h2>");
		break;
		
	case 2:  // mix of uploaded and revised by nlic
		// email LT Officer - uploaded by nlic
		String query = "SELECT * FROM login WHERE roles LIKE '%lt%'";
		String[] emailto1 = workflow.getEmailAddresses(query, "");
		String emailsub1 = "PRoAWorkflow: Action Required from Learning & Teaching Officer";
		String emailmsg1 = "NLiCs have uploaded their assessments. Please click <a href=\"" + link + "\"> this link </a> " + 
							"to Sign in as a Learning & Teaching Officer and then Check Compliance of Assessments.";
		util.sendEmail(emailto1, emailsub1, emailmsg1);
		
		// email DH - revised by nlic
		String disc = workflow.getDiscipline(user);
		query = "SELECT * FROM login WHERE discipline=\'" + disc + "\' AND roles LIKE '%dh%'";
		String[] emailto2 = workflow.getEmailAddresses(query, "");
		String emailsub2 = "PRoAWorkflow: Action Required from Discipline Head";
		String emailmsg2 = "NLiCs have revised their assessments. Please click <a href=\"" + link + "\"> this link </a> " + 
							"to Sign in as a Discipline Head and then Approve Revised Assessments.";
		util.sendEmail(emailto2, emailsub2, emailmsg2);

		webmsg = "The L&T Officer and/or Discipline Head have been informed to check uploaded/revised assessments!";
		out.print("<h2><font color=\"#3c1a50\">" + webmsg + "</font></h2>");
		break;
		
	case 1: // only revised by nlic
		// email DH - revised by nlic
		disc = workflow.getDiscipline(user);
		query = "SELECT * FROM login WHERE discipline=\'" + disc + "\' AND roles LIKE '%dh%'";
		emailto = workflow.getEmailAddresses(query, "");
		emailsub = "PRoAWorkflow: Action Required from Discipline Head";
		emailmsg = "NLiCs have revised their assessments. Please click <a href=\"" + link + "\"> this link </a> " + 
					"to Sign in as a Discipline Head and then Approve Revised Assessments.";
		util.sendEmail(emailto, emailsub, emailmsg);

		webmsg = "The Discipline Head has been informed to check revised assessments!";
		out.print("<h2><font color=\"#3c1a50\">" + webmsg + "</font></h2>");
		break;
		
	case 0: // only uploaded by nlic
		// email LT Officer - uploaded by nlic
		query = "SELECT * FROM login WHERE roles LIKE '%lt%'";
		emailto = workflow.getEmailAddresses(query, "");
		emailsub = "PRoAWorkflow: Action Required from Learning & Teaching Officer";
		emailmsg = "NLiCs have uploaded their assessments. Please click <a href=\"" + link + "\"> this link </a> " + 
							"to Sign in as a Learning & Teaching Officer and then Check Compliance of Assessments.";
		util.sendEmail(emailto, emailsub, emailmsg);
		
		webmsg = "The LT Officer has been informed to check uploaded assessments!";
		out.print("<h2><font color=\"#3c1a50\">" + webmsg + "</font></h2>");
		break;
		
	default:
		webmsg = "Something is wrong!";
		out.print("<h2><font color=\"#cc0000\">" + webmsg + "</font></h2>");

	} 

	out.print("<a href=\"" + loginrole + ".jsp\"><button type=\"submit\" id=\"backtohome\"> " +
				"<i class=\"fa fa-home\"></i> Back to Home</button></a>");
	%>

</body>
</html>
