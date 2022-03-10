<%@page language="java" pageEncoding="utf-8" contentType="text/html; charset=utf-8" %>
<%@ page import="java.sql.*, java.util.*, java.net.*, 
   oracle.jdbc.*, oracle.sql.*" %>
 
<%
// Change these details to suit your database and user details
 
String connStr = "jdbc:oracle:thin:@//servername:1521/pdb1";
String dbUser  = "scott";
String dbPass  = "tiger";
 
// The table we're running queries against is called SEARCH_TABLE.
// It must have columns:
//  tk     number  primary key,     (primary key is important for document services)
//  title  varchar2(2000),
//  text   clob
// There must be a CONTEXT index called IDX_SEARCH_TABLE on the text column
 
request.setCharacterEncoding("UTF-8");
 
java.util.Properties info=new java.util.Properties();
Connection conn  = null;
ResultSet rset   = null;
OracleCallableStatement callStmt = null;
Statement stmt   = null;
String userQuery = null;
String myQuery   = null;
String action    = null;
String theTk     = null;
URLEncoder myEncoder;
int count=0;
int loopNum=0;
int startNum=0;
 
userQuery     =   request.getParameter("query");
action        =   request.getParameter("action");
theTk         =   request.getParameter("tk");
 
if (action == null)  action = "";
 
// Connect to database
 
try {
  DriverManager.registerDriver(new oracle.jdbc.driver.OracleDriver() );
  info.put ("user",     dbUser);
  info.put ("password", dbPass);
  conn      = DriverManager.getConnection(connStr,info);
}
  catch (SQLException e) {
%>    <b>Error: </b> <%= e %><p>  <%
  } 
 
if ( action.equals("doHTML") ) {
  // Directly display the text of the document
  try {
 
    // not attempting to share the output table for this example, we'll truncate it each time
    conn.createStatement().execute("truncate table OUTPUT_TABLE");
 
    String sql = "{ call ctx_doc.filter( index_name=>'IDX_SEARCH_TABLE', textkey=> '" + theTk + "', restab=>'OUTPUT_TABLE', plaintext=>false ) }";
    PreparedStatement s = conn.prepareCall( sql );
    s.execute();
 
    sql = "select document from output_table where rownum = 1";
    stmt = conn.createStatement();
    rset = stmt.executeQuery(sql);
 
    rset.next();
    oracle.sql.CLOB res = (oracle.sql.CLOB) rset.getClob(1);
    // should fetch from clob piecewise, but to keep it simple we'll just fetch 32K to a string
    String txt = res.getSubString(1, 32767);
    out.println(txt);
  }
  catch (SQLException e) {
%>    <b>Error: </b> <%= e %><p> <%
  }
}
else if ( action.equals("doHighlight") ) {
  // Display the text of the document with highlighting from the "markup" function
  try {
 
    // not attempting to share the output table for this example, we'll truncate it each time
    conn.createStatement().execute("truncate table OUTPUT_TABLE");
 
    String sql = "{ call ctx_doc.markup( index_name=>'IDX_SEARCH_TABLE', textkey=> '" + theTk + "', text_query => '" + userQuery + "', restab=>'OUTPUT_TABLE', plaintext=>false, starttag => '<i><font color=\"red\">', endtag => '</font></i>' ) }";
    PreparedStatement s = conn.prepareCall( sql );
    s.execute();
 
    sql = "select document from output_table where rownum = 1";
    stmt = conn.createStatement();
    rset = stmt.executeQuery(sql);
 
    rset.next();
    oracle.sql.CLOB res = (oracle.sql.CLOB) rset.getClob(1);
    // should fetch from clob piecewise, but to keep it simple we'll just fetch 32K to a string
    String txt = res.getSubString(1, 32767);
    out.println(txt);
  }
  catch (SQLException e) {
%>    <b>Error: </b> <%= e %><p> <%
  }
}
 
else if ( action.equals("doThemes") ) {
  // Display the text of the document with highlighting from the "markup" function
  try {
 
    // not attempting to share the output table for this example, we'll truncate it each time
    conn.createStatement().execute("truncate table THEME_TABLE");
 
    String sql = "{ call ctx_doc.themes( index_name=>'IDX_SEARCH_TABLE', textkey=> '" + theTk + "', restab=>'THEME_TABLE') }";
    PreparedStatement s = conn.prepareCall( sql );
    s.execute();
 
    sql = "select * from ( select theme, weight from theme_table order by weight desc ) where rownum <= 20";
    stmt = conn.createStatement();
    rset = stmt.executeQuery(sql);
    int    weight = 0;
    String theme  = "";
%>
    <h2>The top 20 themes of the document</h2>
    <table BORDER=1 CELLSPACING=0 CELLPADDING=0"
       <tr bgcolor="#CCCC99">
       <th><font face="arial" color="#336699">Theme</th>
       <th><font face="arial" color="#336699">Weight</th>
       </tr>
<%
    while ( rset.next() ) {
 
      theme  = rset.getString(1); 
      weight = (int)rset.getInt(2);
%>
       <tr bgcolor="ffffe0">
         <td align="center"><font face="arial"><b> <%= theme  %> </b></font></td>
         <td align="center"><font face="arial"> <%= weight %></font></td>
       </tr>
<%
    }
 
%>
</table>
<%
  }
  catch (SQLException e) {
%>    <b>Error: </b> <%= e %><p> <%
  }
}
else if ( action.equals("doGists") ) {
  // Display the text of the document with highlighting from the "markup" function
  try {
 
    // not attempting to share the output table for this example, we'll truncate it each time
    conn.createStatement().execute("truncate table GIST_TABLE");
 
    String sql = "{ call ctx_doc.gist( index_name=>'IDX_SEARCH_TABLE', textkey=> '" + theTk + "', restab=>'GIST_TABLE', query_id=>1) }";
    PreparedStatement s = conn.prepareCall( sql );
    s.execute();
 
    sql = "select pov, gist from gist_table where pov = 'GENERIC' and query_id = 1";
    stmt = conn.createStatement();
    rset = stmt.executeQuery(sql);
    String pov   = "";
    String gist  = "";
 
    while ( rset.next() ) {
 
      pov   = rset.getString(1); 
      oracle.sql.CLOB gistClob = (oracle.sql.CLOB) rset.getClob(2);
 
      out.println("<h3>Document Gist for Point of View: " + pov + "</h3>");
      gist = gistClob.getSubString(1, 32767);
      out.println(gist);
 
    }
 
%>
</table>
<%
  }
  catch (SQLException e) {
%>    <b>Error: </b> <%= e %><p> <%
  }
}
 
if ( (action.equals("")) && ( (userQuery == null) || (userQuery.length() == 0) ) ) {
%>
  <html>
    <title>Text Search</title>
    <body>
      <table width="100%">
        <tr bgcolor="#336699">
          <td><font face="arial" align="left" 
          color="#CCCC99" size="+2">Text Search</td>
        </tr>
      </table>
    <center>
      <form method = post>
      Search for:
      <input type="text" name="query" size = "30">
      <input type="submit" value="Search">
      </form>
    </center>
    </body>
  </html>
<%
}
else if (action.equals("") ) {
%>
  <html>
    <title>Text Search Result Page</title>
    <body text="#000000" bgcolor="#FFFFFF" link="#663300" 
          vlink="#996633" alink="#ff6600">
      <table width="100%">
        <tr bgcolor="#336699">
          <td><font face="arial" align="left" 
                 color="#CCCC99" size=+2>Text Search</td>
        </tr>
      </table>
    <center>
      <form method = post action="TextSearchApp.jsp">
      Search for:
      <input type=text name="query" value="<%= userQuery %>" size = 30>
      <input type=submit value="Search">
      </form>
    </center>
<%
  myQuery   =   URLEncoder.encode(userQuery);
  try {
 
    stmt      = conn.createStatement();
 
    String numStr =   request.getParameter("sn");
    if(numStr!=null)
      startNum=Integer.parseInt(numStr);
    String theQuery =   translate(userQuery);
 
    callStmt =(OracleCallableStatement)conn.prepareCall("begin "+
         "?:=ctx_query.count_hits(index_name=>'IDX_SEARCH_TABLE', "+
         "text_query=>?"+
         "); " +
         "end; ");
    callStmt.setString(2,theQuery);
    callStmt.registerOutParameter(1, OracleTypes.NUMBER);
    callStmt.execute();
    count=((OracleCallableStatement)callStmt).getNUMBER(1).intValue();
    if(count>=(startNum+20)){
%>
    <font color="#336699" FACE="Arial" SIZE=+1>Results
           <%=startNum+1%> - <%=startNum+20%> of <%=count%> matches
<%
    }
    else if(count>0){
%>
    <font color="#336699" FACE="Arial" SIZE=+1>Results
           <%=startNum+1%> - <%=count%> of <%=count%> matches
<%
    }
    else {
%>
    <font color="#336699" FACE="Arial" SIZE=+1>No match found
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
    String ctxQuery = 
        " select /*+ FIRST_ROWS */ " + 
        "   tk, TITLE, score(1) scr, " +
        "   ctx_doc.snippet ('IDX_SEARCH_TABLE', tk, '" + theQuery + "') " + 
        " from search_table " + 
        " where contains(TEXT, '"+theQuery+"',1 ) > 0 " +
        " order by score(1) desc"; 
    rset = stmt.executeQuery(ctxQuery);
    String   tk           = null;
    String[] colToDisplay = new String[1];
    int      myScore      = 0;
    String   snippet      = "";
    int      items        = 0;
    while (rset.next()&&items< 20) {
      if(loopNum>=startNum)
      {
        tk = rset.getString(1);
        colToDisplay[0] = rset.getString(2);
        myScore         = (int)rset.getInt(3);
        snippet         = rset.getString(4);
        items++;
        if (items == 1) {
%>
        <center>
          <table BORDER=1 CELLSPACING=0 CELLPADDING=0 width="100%"
            <tr bgcolor="#CCCC99">
              <th><font face="arial" color="#336699">Score</th>
              <th><font face="arial" color="#336699">TITLE</th>
              <th><font face="arial" color="#336699">Snippet</th>
              <th> <font face="arial" 
                       color="#336699">Document Services</th>
            </tr>
<%   } %>
      <tr bgcolor="#FFFFE0">
        <td ALIGN="CENTER"> <%= myScore %>%</td>
        <td> <%= colToDisplay[0] %> </td>
        <td> <%= snippet %> </td>
        <td>
          <a href="TextSearchApp.jsp?action=doHTML&tk=<%= tk %>">HTML</a> &nbsp;
          <a href="TextSearchApp.jsp?action=doHighlight&tk=<%= tk %>&query=<%= theQuery %>">Highlight</a> &nbsp;
          <a href="TextSearchApp.jsp?action=doThemes&tk=<%= tk %>&query=<%= theQuery %>">Themes</a> &nbsp;
          <a href="TextSearchApp.jsp?action=doGists&tk=<%= tk %>">Gist</a> &nbsp;
        </td>
      </tr>
<%
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