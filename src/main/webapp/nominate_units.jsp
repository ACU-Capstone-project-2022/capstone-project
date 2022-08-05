<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ page import="java.sql.*, com.beanlib.DBResult, com.beanlib.Workflow" %>
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

<title>Nominate Units to be Reviewed</title>
</head>

<body>
	<header>
		<h1>Peer Review of Assessment Workflow System</h1>
	</header>

	<%
	// Test if it is unauthorised or not
	if (session.getAttribute("login") == null || session.getAttribute("login") == " ") {
		response.sendRedirect("index.jsp");
		return;
	}

	// Start of the workflow - no unit nominated for review
	String sqlquery = "SELECT * FROM units WHERE 2boffered=1 AND 2breviewed=1";
	DBResult dbr = workflow.getUnits(sqlquery); // Retrieve relevant units using sqlquery
	Connection conn = dbr.getCONN();
	
	PreparedStatement ps = dbr.getPS();
	ResultSet rs = dbr.getRS();
			
	// Test whether unit nomination for review is already done
	if (rs.next()) { 
		out.print("<font color=\"#3c1a50\"><h2> You have already nominated units for review. <h2></font>");
		out.print("<a href=\"lt.jsp\"><button type=\"submit\" id=\"backtohome\">" +
						"<i class=\"fa fa-home\"></i> Back to Home</button></a>");
		
		rs.close();
		ps.close();
		conn.close();
		
		return;
	}
	// If any reviewed units are not nominated yet
	else {
		rs.close();
		ps.close();
		conn.close();
	}
	%>
	
	<div class="container">
		<h2>You Must Nominate All Units to be Peer Reviewed</h2>
		<form method="post" action="show_units4review.jsp" onsubmit="btn_confirm.disabled = true; return true;">
			<table class="table table-bordered table-striped">
				<thead> 	
					<tr>
						<th>Offer?</th>
						<th>Review?</th>
						<th>Discipline</th>
						<th>Unit Code</th>
						<th>Unit Title</th>
					</tr>
				</thead>
				<tbody>
				
					<%
					sqlquery = "SELECT * FROM units ORDER BY discipline ASC, code ASC";

					dbr = workflow.getUnits(sqlquery);

					conn = dbr.getCONN();
					ps = dbr.getPS();
					rs = dbr.getRS();

					int row = 0;
					while (rs.next()) {
						out.print("<tr>");
						// value of each checkbox is set to the corresponding row number to record which row is checked
						out.print("<td class=\"clickable\" onclick=\"getElementById('checkbox1_" + row + "').click();\">" + // class=\"clickable\" was added on 4May2022
									"<input type=\"checkbox\" name=\"2boffered\" value = \"" + row + "\" id=\"checkbox1_" + row + "\" onclick=\"this.click()\"></td>");
						// value of each checkbox is set to the corresponding row number to record which row is checked
						out.print("<td class=\"clickable\" onclick=\"getElementById('checkbox2_" + row + "').click();\">" + // class=\"clickable\" was added on 4May2022
									"<input type=\"checkbox\" name=\"2breviewed\" value = \"" + row + "\" id=\"checkbox2_" + row + "\" onclick=\"this.click()\"></td>");
						out.print("<td>" + rs.getString("discipline") + "</td>");
						out.print("<td>" + rs.getString("code") + "</td>");
						out.print("<td>" + rs.getString("name") + "</td>");
						out.print("</tr>");

						row++;
					}

					rs.close();
					ps.close();
					conn.close();
					%>
				</tbody>
			</table>
			<button type="submit" id="btn_submit" onclick="showProgress()"> Submit</button>
			<i id="progress" class="fa fa-spinner fa-spin" style="display:none"></i> <!-- ADDED on 19Apr2022 -->
		</form>
		<br>
		<a href="lt.jsp"><button type="submit" id="backtohome"><i class="fa fa-home"></i> Cancel</button></a>
	</div>
</body>
</html>
