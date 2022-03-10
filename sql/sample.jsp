<%@ page import="java.sql.*, java.util.*, java.net.*, 
   oracle.jdbc.*, oracle.jsp.dbutil.*" %>
<%@ page contentType="text/html;charset=UTF-8" %>
<% oracle.jsp.util.PublicUtil.setReqCharacterEncoding(request, "UTF-8"); %>
<jsp:useBean id="name" class="oracle.jsp.jml.JmlString" scope ="request" >
<jsp:setProperty name="name" property="value" param="query" />
</jsp:useBean>
 
<%
String connStr="jdbc:oracle:thin:@jsmith-pc.us.oracle.com:1521:zippy922";
 
java.util.Properties info=new java.util.Properties();
Connection conn = null;
ResultSet rset = null;
OracleCallableStatement callStmt = null;
Statement stmt = null;
String userQuery = null;
String myQuery = null;
URLEncoder myEncoder;
int count=0;
int loopNum=0;
int startNum=0;
if (name.isEmpty()) {
%>
  <html>
    <title>Text Search</title>
    <body>
      <table width="100%">
        <tr bgcolor="#336699">
          <td><font face="arial, helvetica" align="left" 
          color="#CCCC99" size=+2>Text Search</td>
        </tr>
      </table>
    <center>
      <form method = post>
      Search for:
      <input type=text name=query size = 30>
      <input type=submit value="Search">
      </form>
    </center>
    </body>
  </html>
 
<%}
 
else {
%>
  <html>
    <title>Text Search</title>
    <body text="#000000" bgcolor="#FFFFFF" link="#663300" 
          vlink="#996633" alink="#ff6600">
      <table width="100%">
        <tr bgcolor="#336699">
          <td><font face="arial, helvetica" align="left" 
                 color="#CCCC99" size=+2>Text Search</td>
        </tr>
      </table>
    <center>
      <form method = post action="TextSearchApp.jsp">
      Search for:
      <input type=text name="query" value="<%=name.getValue() %>" size = 30>
      <input type=submit value="Search">
      </form>
    </center>
<%
  try {
    DriverManager.registerDriver(new oracle.jdbc.driver.OracleDriver() );
    info.put ("user", "jsmith");
    info.put ("password","hello");
    conn = DriverManager.getConnection(connStr,info);
    stmt = conn.createStatement();
    userQuery =   request.getParameter("query");
    myQuery =   URLEncoder.encode(userQuery);
    String numStr =   request.getParameter("sn");
    if(numStr!=null)
      startNum=Integer.parseInt(numStr);
    String theQuery =   translate(userQuery);
    callStmt =(OracleCallableStatement)conn.prepareCall("begin "+
         "?:=ctx_query.count_hits(index_name=>'ULTRA_IDX1', "+
         "text_query=>?"+
         "); " +
         "end; ");
    callStmt.setString(2,theQuery);
    callStmt.registerOutParameter(1, OracleTypes.NUMBER);
    callStmt.execute();
    count=((OracleCallableStatement)callStmt).getNUMBER(1).intValue();
    if(count>=(startNum+20)){
%>
    <font color="#336699" FACE="Arial,Helvetica" SIZE=+1>Results
           <%=startNum+1%> - <%=startNum+20%> of <%=count%> matches
<%
    }
    else if(count>0){
%>
    <font color="#336699" FACE="Arial,Helvetica" SIZE=+1>Results
           <%=startNum+1%> - <%=count%> of <%=count%> matches
<%
    }
    else {
%>
    <font color="#336699" FACE="Arial,Helvetica" SIZE=+1>No match found
<%
    }
%>
  <table width="100%">
  <TR ALIGN="RIGHT">
<%
  if((startNum>0)&(count<=startNum+20))
  {
%>
    <TD ALIGN="RIGHT">
    <a href="TextSearchApp.jsp?sn=<%=startNum-20 %>&query=
            <%=myQuery %>">previous20</a>
    </TD>
<%
  }
  else if((count>startNum+20)&(startNum==0))
  {
%>
    <TD ALIGN="RIGHT">
    <a href="TextSearchApp.jsp?sn=<%=startNum+20 
          %>&query=<%=myQuery %>">next20</a>
    </TD>
<%
  }
  else if((count>startNum+20)&(startNum>0))
  {
%>
    <TD ALIGN="RIGHT">
    <a href="TextSearchApp.jsp?sn=<%=startNum-20 %>&query=
              <%=myQuery %>">previous20</a>
    <a href="TextSearchApp.jsp?sn=<%=startNum+20 %>&query=
              <%=myQuery %>">next20</a>
    </TD>
<%
  }
%>
  </TR>
  </table>
<%
    String ctxQuery = "select /*+ FIRST_ROWS */ rowid, 'TITLE',
     score(1) scr from 'ULTRA_TAB1' where contains('TEXT', '"+theQuery+"',1 )
     > 0 order by score(1) desc";
    rset = stmt.executeQuery(ctxQuery);
    String color = "ffffff";
    String rowid = null;
    String fakeRowid = null;
    String[] colToDisplay = new String[1];
    int myScore = 0;
    int items = 0;
    while (rset.next()&&items< 20) {
      if(loopNum>=startNum)
      {
        rowid = rset.getString(1);
        fakeRowid = URLEncoder.encode(rowid);
        colToDisplay[0] = rset.getString(2);
        myScore = (int)rset.getInt(3);
        items++;
        if (items == 1) {
%>
        <center>
          <table BORDER=1 CELLSPACING=0 CELLPADDING=0 width="100%"
            <tr bgcolor="#CCCC99">
              <th><font face="arial, helvetica" color="#336699">Score</th>
              <th><font face="arial, helvetica" color="#336699">TITLE</th>
              <th> <font face="arial, helvetica" 
                       color="#336699">Document Services</th>
            </tr>
<%   } %>
      <tr bgcolor="#FFFFE0">
        <td ALIGN="CENTER"> <%= myScore %>%</td>
        <td> <%= colToDisplay[0] %>
        <td>
        </td>
      </tr>
<%
      if (color.compareTo("ffffff") == 0)
        color = "eeeeee";
      else
        color = "ffffff";
      }
      loopNum++;
    }
} catch (SQLException e) {
%>
    <b>Error: </b> <%= e %><p>
<%
} finally {
  if (conn != null) conn.close();
  if (stmt != null) stmt.close();
  if (rset != null) rset.close();
  }
%>
  </table>
  </center>
  <table width="100%">
  <TR ALIGN="RIGHT">
<%
  if((startNum>0)&(count<=startNum+20))
  {
%>
    <TD ALIGN="RIGHT">
    <a href="TextSearchApp.jsp?sn=<%=startNum-20 %>&query=
               <%=myQuery %>">previous20</a>
    </TD>
<%
  }
  else if((count>startNum+20)&(startNum==0))
  {
%>
    <TD ALIGN="RIGHT">
    <a href="TextSearchApp.jsp?sn=<%=startNum+20 %>&query=
          <%=myQuery %>">next20</a>
    </TD>
<%
  }
  else if((count>startNum+20)&(startNum>0))
  {
%>
    <TD ALIGN="RIGHT">
    <a href="TextSearchApp.jsp?sn=<%=startNum-20 %>&query=
          <%=myQuery %>">previous20</a>
    <a href="TextSearchApp.jsp?sn=<%=startNum+20 %>&query=
          <%=myQuery %>">next20</a>
    </TD>
<%
  }
%>
  </TR>
  </table>
  </body></html>
<%}
 
%>
<%!
   public String translate (String input)
   {
      Vector reqWords = new Vector();
      StringTokenizer st = new StringTokenizer(input, " '", true);
      while (st.hasMoreTokens())
      {
        String token = st.nextToken();
        if (token.equals("'"))
        {
           String phrase = getQuotedPhrase(st);
           if (phrase != null)
           {
              reqWords.addElement(phrase);
           }
        }
        else if (!token.equals(" "))
        {
           reqWords.addElement(token);
        }
      }
      return getQueryString(reqWords);
   }
 
   private String getQuotedPhrase(StringTokenizer st)
   {
      StringBuffer phrase = new StringBuffer();
      String token = null;
      while (st.hasMoreTokens() && (!(token = st.nextToken()).equals("'")))
      {
        phrase.append(token);
      }
      return phrase.toString();
   }
 
 
   private String getQueryString(Vector reqWords)
   {
      StringBuffer query = new StringBuffer("");
      int length = (reqWords == null) ? 0 : reqWords.size();
      for (int ii=0; ii < length; ii++)
      {
         if (ii != 0)
         {
           query.append(" & ");
         }
         query.append("{");
         query.append(reqWords.elementAt(ii));
         query.append("}");
      }
      return query.toString();
   }
%>