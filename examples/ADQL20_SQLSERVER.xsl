<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0"
		xmlns="http://www.ivoa.net/xml/v2.0/adql" 
		xmlns:ad="http://www.ivoa.net/xml/v2.0/adql"
		xmlns:xsd="http://www.w3.org/2001/XMLSchema" 
		xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
	
	<!-- 
		Stylesheet to convert ADQL/x v1.0 to an SQL string
		Version 1.0 - first release - July 8, 2005
		Aurelien STEBE - ESAC - ESA
		Aurelien.Stebe@sciops.esa.int
		
		Current stylesheet was derived from SQLSERVER-8.00.xsl
	 -->
	
    <xsl:output method="text" indent="no"/>
   		
    <xsl:param name="spaceCharacter" select="' '"/>      		
   		
	<!-- the root template -->
	

	<xsl:template match="/">
	       <xsl:apply-templates select="*"/>
	</xsl:template>
	
	
	<!-- the 'select' template -->
	
	<xsl:template match="ad:Select">
		<xsl:text>Select </xsl:text>
		<xsl:apply-templates select="ad:Allow"/>
		<xsl:apply-templates select="ad:Restrict"/>
		<xsl:apply-templates select="ad:SelectionList"/>
		<xsl:apply-templates select="ad:From"/>
		<xsl:apply-templates select="ad:Where"/>
		<xsl:apply-templates select="ad:GroupBy"/>
		<xsl:apply-templates select="ad:Having"/>
		<xsl:apply-templates select="ad:OrderBy"/>
	</xsl:template>
	
	<!-- the "main" elements -->
	
	<xsl:template match="ad:SelectionList">
		<xsl:variable name="list">
			<xsl:for-each select="ad:Item">
				<xsl:apply-templates select="."/>
				<xsl:text>,</xsl:text>
				<xsl:value-of select="$spaceCharacter"/>
			</xsl:for-each>
		</xsl:variable>
		<xsl:value-of select="substring($list, 1, string-length($list)-2)"/>
	</xsl:template>
	
	<xsl:template match="*[ contains(@xsi:type, 'aliasSelectionItemType') ]">
		<xsl:apply-templates select="ad:Expression"/>
		<xsl:text> as </xsl:text>
	    <xsl:value-of select="@As"/>
	</xsl:template>
	
	<xsl:template match="*[ contains(@xsi:type, 'allSelectionItemType') ]">
        <xsl:call-template name="qualifiedName" />
		<xsl:text>*</xsl:text>
	</xsl:template>
	
	<xsl:template match="ad:From">
		<xsl:variable name="list">
			<xsl:for-each select="ad:Table">
				<xsl:apply-templates select="."/>
				<xsl:text>, </xsl:text>
			</xsl:for-each>
		</xsl:variable>		
		<xsl:text> From </xsl:text>
		<xsl:value-of select="substring($list, 1, string-length($list)-2)"/>
		<xsl:text> </xsl:text>
	</xsl:template>

	<!--+
	    | NB: This is about as close as one dare use the contains function rather than
	    |     the substring-after function and be able to rely upon case sensitivity 
	    |     to do the correct thing.
	    +-->
	<xsl:template match="*[ contains(@xsi:type, 'tableType') ]">
	    <xsl:call-template name="qualifiedName" />
		<xsl:if test="@Alias">
			<xsl:text> as </xsl:text>
			<xsl:value-of select="@Alias"/>
		</xsl:if>
	</xsl:template>	
	
 	<xsl:template match="*[ contains(@xsi:type, 'joinTableType') ] | ad:JoinedTable">	    
	    <xsl:variable name="joinType" select="ad:Qualifier" />
	    <xsl:apply-templates select="ad:Tables/ad:fromTableType[1]"/>
	    <xsl:if test="@NaturalJoin = 'true'">
			<xsl:text> NATURAL</xsl:text>
		</xsl:if>
        <xsl:choose>
           <xsl:when test="$joinType='LEFT_OUTER'" ><xsl:text> LEFT OUTER JOIN </xsl:text></xsl:when>
           <xsl:when test="$joinType='RIGHT_OUTER'" ><xsl:text> RIGHT OUTER JOIN </xsl:text></xsl:when>           
           <xsl:when test="$joinType='FULL_OUTER'" ><xsl:text> FULL OUTER JOIN </xsl:text></xsl:when>           
           <xsl:when test="$joinType='INNER'" ><xsl:text> INNER JOIN </xsl:text></xsl:when>    
           <xsl:when test="$joinType='CROSS'" ><xsl:text> CROSS JOIN </xsl:text></xsl:when> 
           <xsl:otherwise><xsl:text> JOIN </xsl:text></xsl:otherwise>  
        </xsl:choose> 
        <xsl:apply-templates select="ad:Tables/ad:fromTableType[2]"/>  
        <xsl:apply-templates select="ad:JoinSpecification"/>          
	</xsl:template>
	
		
	<xsl:template match="*[ contains(@xsi:type, 'derivedTableType') ]">	    
	    <xsl:text>( </xsl:text>
        <xsl:choose>
           <xsl:when test="ad:SubQuery/ad:QueryExpression/ad:JoinedTable" >
              <xsl:apply-templates select="ad:SubQuery/ad:QueryExpression/ad:JoinedTable"/>          
           </xsl:when>
           <xsl:otherwise>
           	  <xsl:apply-templates select="ad:SubQuery/ad:QueryExpression/ad:Select"/>
           </xsl:otherwise>  
        </xsl:choose>
        <xsl:text> )</xsl:text> 
        <xsl:if test="@Alias">
			<xsl:text> as </xsl:text>
			<xsl:value-of select="@Alias"/>
		</xsl:if>        
	</xsl:template>

	<xsl:template match="ad:Where">  
		<xsl:text> Where </xsl:text>
		<xsl:apply-templates select="ad:Condition"/>
		<xsl:value-of select="$spaceCharacter"/>
	</xsl:template>

	<xsl:template match="ad:GroupBy">
		<xsl:variable name="list">
			<xsl:for-each select="ad:Column">
				<xsl:apply-templates select="."/>
				<xsl:text>,</xsl:text>
				<xsl:value-of select="$spaceCharacter"/>
			</xsl:for-each>
		</xsl:variable>		
		<xsl:text> Group By </xsl:text>
		<xsl:value-of select="substring($list, 1, string-length($list)-2)"/>
		<xsl:value-of select="$spaceCharacter"/>
	</xsl:template>

	<xsl:template match="ad:Having"> 	
		<xsl:text> Having </xsl:text>
		<xsl:apply-templates select="ad:Condition"/>
		<xsl:value-of select="$spaceCharacter"/>
	</xsl:template>
	
	<xsl:template match="ad:OrderBy">
		<xsl:variable name="list">
			<xsl:for-each select="ad:Item">
				<xsl:apply-templates select="ad:Expression"/>
				<xsl:apply-templates select="ad:Order"/>
				<xsl:text>,</xsl:text>
				<xsl:value-of select="$spaceCharacter"/>
			</xsl:for-each>
		</xsl:variable>
		<xsl:text> Order By </xsl:text>
		<xsl:value-of select="substring($list, 1, string-length($list)-2)"/>
		<xsl:value-of select="$spaceCharacter"/>
	</xsl:template>
	
	<xsl:template match="ad:Order">
		<xsl:text> </xsl:text>
		<xsl:value-of select="@Direction"/>
	</xsl:template>
	
	<!-- the 'searchType' templates -->
	
	<xsl:template match="*[ contains(@xsi:type, 'intersectionSearchType') ]">    
		<xsl:text>(</xsl:text>
		<xsl:apply-templates select="ad:Condition[1]"/>
		<xsl:text>) And (</xsl:text>
		<xsl:apply-templates select="ad:Condition[2]"/>
		<xsl:text>)</xsl:text>
	</xsl:template>	

	<xsl:template match="*[ contains(@xsi:type, 'unionSearchType') ]">
	    <xsl:text>(</xsl:text>
		<xsl:apply-templates select="ad:Condition[1]"/>
		<xsl:text>) Or (</xsl:text>
		<xsl:apply-templates select="ad:Condition[2]"/>	
        <xsl:text>)</xsl:text>	
	</xsl:template>	

	<xsl:template match="*[ contains(@xsi:type, 'likePredType') ]">
		<xsl:apply-templates select="ad:Arg"/>	
		<xsl:text> Like </xsl:text>
		<xsl:apply-templates select="ad:Pattern"/>
		<xsl:value-of select="$spaceCharacter"/>
	</xsl:template>	

	<xsl:template match="*[ contains(@xsi:type, 'notLikePredType') ]">
		<xsl:apply-templates select="ad:Arg"/>	
		<xsl:text> Not Like </xsl:text>
		<xsl:apply-templates select="ad:Pattern"/>
		<xsl:value-of select="$spaceCharacter"/>
	</xsl:template>	

	<xsl:template match="*[ contains(@xsi:type, 'inclusiveSearchType') ]">
		<xsl:apply-templates select="ad:Expression"/>
		<xsl:text> In (</xsl:text>		
		<xsl:apply-templates select="ad:InPredicateValue"/>		
		<xsl:text>)</xsl:text>
		<xsl:value-of select="$spaceCharacter"/>
	</xsl:template>	

	<xsl:template match="*[ contains(@xsi:type, 'exclusiveSearchType') ]">
		<xsl:apply-templates select="ad:Expression"/>
		<xsl:text> Not In (</xsl:text>		
		<xsl:apply-templates select="ad:InPredicateValue"/>		
		<xsl:text>)</xsl:text>
		<xsl:value-of select="$spaceCharacter"/>
	</xsl:template>	
	
	<xsl:template match="ad:InPredicateValue">
		<xsl:choose>
		   <xsl:when test="ad:InValueList" >
              <xsl:apply-templates select="ad:InValueList"/>          
           </xsl:when>
           <xsl:when test="ad:SubQuery/ad:QueryExpression/ad:JoinedTable" >
              <xsl:apply-templates select="ad:SubQuery/ad:QueryExpression/ad:JoinedTable"/>          
           </xsl:when>
           <xsl:otherwise>
           	  <xsl:apply-templates select="ad:SubQuery/ad:QueryExpression/ad:Select"/>
           </xsl:otherwise>  
        </xsl:choose>
	</xsl:template>
	
	<xsl:template match="ad:InValueList">
		<xsl:variable name="list">
			<xsl:for-each select="ad:Item">
				<xsl:apply-templates select="."/>
				<xsl:text>,</xsl:text>
				<xsl:value-of select="$spaceCharacter"/>
			</xsl:for-each>
		</xsl:variable>
		<xsl:value-of select="substring($list, 1, string-length($list)-2)"/>
	</xsl:template>

	<xsl:template match="*[ contains(@xsi:type, 'closedSearchType') ]">
		<xsl:text>(</xsl:text>
		<xsl:apply-templates select="ad:Condition"/>
		<xsl:text>)</xsl:text>
	</xsl:template>	

	<xsl:template match="*[ contains(@xsi:type, 'comparisonPredType') ] | *[@Comparison]">
		<xsl:apply-templates select="ad:Arg[1]"/>
		<xsl:text> </xsl:text>
		<xsl:value-of select="@Comparison"/>
		<xsl:text> </xsl:text>
		<xsl:apply-templates select="ad:Arg[2]"/>
	</xsl:template>
	
	<xsl:template match="*[ contains(@xsi:type, 'betweenPredType') ]">   
		<xsl:apply-templates select="ad:Arg[1]"/>
		<xsl:text> Between </xsl:text>
		<xsl:apply-templates select="ad:Arg[2]"/>
		<xsl:text> And </xsl:text>
		<xsl:apply-templates select="ad:Arg[3]"/>
		<xsl:value-of select="$spaceCharacter"/>
	</xsl:template>	

	<xsl:template match="*[ contains(@xsi:type, 'notBetweenPredType') ]">
		<xsl:apply-templates select="ad:Arg[1]"/>
		<xsl:text> Not Between </xsl:text>
		<xsl:apply-templates select="ad:Arg[2]"/>  
		<xsl:text> And </xsl:text>
		<xsl:apply-templates select="ad:Arg[3]"/>
		<xsl:value-of select="$spaceCharacter"/>
	</xsl:template>
	
	<xsl:template match="*[ contains(@xsi:type, 'nullPredType') ]">   
		<xsl:apply-templates select="ad:Column" />
		<xsl:text> IS NULL </xsl:text>	
	</xsl:template>
	
	<xsl:template match="*[ contains(@xsi:type, 'notNullPredType') ]">
		<xsl:apply-templates select="ad:Column" />
		<xsl:text> IS NOT NULL </xsl:text>
	</xsl:template>
	
	<xsl:template match="*[ contains(@xsi:type, 'existsPredType') ]">
	    <xsl:text> EXISTS (</xsl:text>
		<xsl:choose>
           <xsl:when test="ad:SubQuery/ad:QueryExpression/ad:JoinedTable" >
              <xsl:apply-templates select="ad:SubQuery/ad:QueryExpression/ad:JoinedTable"/>          
           </xsl:when>
           <xsl:otherwise>
           	  <xsl:apply-templates select="ad:SubQuery/ad:QueryExpression/ad:Select"/>
           </xsl:otherwise>  
        </xsl:choose>
	    <xsl:text>) </xsl:text>
	</xsl:template>	
	
	<xsl:template match="*[ contains(@xsi:type, 'inverseSearchType') ]">
		<xsl:text> NOT </xsl:text>
		<xsl:apply-templates select="ad:Condition"/>
		<xsl:value-of select="$spaceCharacter"/>
	</xsl:template>	
		
	<!-- the 'expressionType' templates -->

	<xsl:template match="*[ contains(@xsi:type, 'closedExprType') ]">
		<xsl:text>(</xsl:text>
		<xsl:apply-templates select="ad:Arg"/>
		<xsl:text>)</xsl:text>
	</xsl:template>	
	
   <!-- KEA: 
       - Added brackets around binary expressions to ensure correct
          precendence
       - Put spaces around operator to avoid issues with e.g. subtracting
          a negated arg. (SQLServer doesn't like doubled - with no spaces)
   -->
	<xsl:template match="*[ contains(@xsi:type, 'binaryExprType') ]">
		<xsl:text>(</xsl:text>
		<xsl:apply-templates select="ad:Arg[1]"/>
		<xsl:text> </xsl:text>
		<xsl:value-of select="@Oper"/>
		<xsl:text> </xsl:text>
		<xsl:apply-templates select="ad:Arg[2]"/>
		<xsl:text>)</xsl:text>
	</xsl:template>	
	
	<xsl:template match="*[ contains(@xsi:type, 'characterValueExpressionType') ]">
        <xsl:variable name="list">
			<xsl:for-each select="ad:CharacterFactor">
				<xsl:apply-templates select="."/>
				<xsl:text> + </xsl:text>
			</xsl:for-each>
		</xsl:variable>
		<xsl:value-of select="substring($list, 1, string-length($list)-4)"/>
	</xsl:template>

	<xsl:template match="*[ contains(@xsi:type, 'unaryExprType') ]">
		<xsl:value-of select="@Oper"/>
		<xsl:apply-templates select="ad:Arg"/>
	</xsl:template>	

	<xsl:template match="*[ contains(@xsi:type, 'columnReferenceType') ] | ad:Column">
	    <xsl:call-template name="qualifiedName" />
	</xsl:template>	

	<xsl:template match="*[ contains(@xsi:type, 'atomType') ]">
		<xsl:apply-templates select="ad:Literal"/>
	</xsl:template>
	
	<xsl:template match="*[ contains(@xsi:type, 'realType') ] | *[ contains(@xsi:type, 'integerType') ]">
		<xsl:value-of select="@Value"/>
	</xsl:template>
	
	<xsl:template match="*[ contains(@xsi:type, 'stringType') ]">
		<xsl:text>'</xsl:text>
		<xsl:value-of select="@Value"/>
		<xsl:text>'</xsl:text>
	</xsl:template>
	
	<xsl:template match="*[ contains(@xsi:type, 'hexStringType') ]">
		<xsl:text>0x</xsl:text>
		<xsl:value-of select="@Value"/>
	</xsl:template>
			
	<xsl:template match="ad:Allow">
		<xsl:value-of select="@Option"/>
		<xsl:text> </xsl:text>
	</xsl:template>
	
	<xsl:template match="ad:Restrict">
		<xsl:text>Top </xsl:text>
		<xsl:value-of select="@Top"/>
		<xsl:text> </xsl:text>
	</xsl:template>	

	<!-- the 'functionType' templates -->
	
	<xsl:template match="*[ contains(@xsi:type, 'trigonometricFunctionType') ]
	                   | *[ contains(@xsi:type, 'mathFunctionType') ]" >
		<xsl:choose>
         	<!-- Deal with ATAN2 as special case -->
         	<xsl:when test="@Name = 'ATAN2'">
            	<xsl:text>ATN2(</xsl:text>
            	<xsl:apply-templates select="ad:Arg[1]"/>
            	<xsl:text>, </xsl:text>
            	<xsl:apply-templates select="ad:Arg[2]"/>
            	<xsl:text>) </xsl:text>
         	</xsl:when>
         	<!-- This is a custom action for TRUNCATE function (not supported) -->
         	<xsl:when test="@Name = 'TRUNCATE'">
           		<xsl:text>ROUND(</xsl:text>
           		<xsl:apply-templates select="ad:Arg[1]"/>
           		<xsl:text>, </xsl:text>
           		<xsl:apply-templates select="ad:Arg[2]"/>
           		<xsl:text>, 1) </xsl:text>      
         	</xsl:when>
         	<xsl:otherwise>
           		<!-- This is the default action for maths/trig functions -->
           		<xsl:value-of select="@Name"/>
           		<xsl:text>(</xsl:text>
           		<xsl:variable name="list">
             		<xsl:for-each select="ad:Arg">
               			<xsl:apply-templates select="."/>
               			<xsl:text>,</xsl:text>
               			<xsl:value-of select="$spaceCharacter"/>
             		</xsl:for-each>
           		</xsl:variable>
           		<xsl:value-of select="substring($list, 1, string-length($list)-2)"/>
           		<xsl:text>) </xsl:text>
         	</xsl:otherwise>
      </xsl:choose>
	</xsl:template>	
	
	<xsl:template match="*[ contains(@xsi:type, 'systemFunctionType') ]
	                   | *[ contains(@xsi:type, 'geometryFunctionType') ]
	                   | *[ contains(@xsi:type, 'userDefinedFunctionType') ]" >
	    <xsl:call-template name="qualifiedName" />
		<xsl:text>(</xsl:text>
		<xsl:variable name="list">
			<xsl:for-each select="ad:Arg">
				<xsl:apply-templates select="."/>
				<xsl:text>,</xsl:text>
				<xsl:value-of select="$spaceCharacter"/>
			</xsl:for-each>
		</xsl:variable>
		<xsl:value-of select="substring($list, 1, string-length($list)-2)"/>		
		<xsl:text>) </xsl:text>
		<xsl:value-of select="$spaceCharacter"/>
	</xsl:template>
	
	<xsl:template match="*[ contains(@xsi:type, 'aggregateFunctionType') ]">
		<xsl:value-of select="@Name"/>
		<xsl:text>( </xsl:text>
		<xsl:apply-templates select="ad:Allow"/>
		<xsl:text> </xsl:text>
		<xsl:apply-templates select="ad:Arg"/>
		<xsl:text> ) </xsl:text>
	</xsl:template>	

	<!-- Join Specification templates -->
	
	<xsl:template match="*[ contains(@xsi:type, 'joinConditionType') ]">
		<xsl:text> ON </xsl:text>  
		<xsl:apply-templates select="ad:Condition"/> 
	</xsl:template>  
	
	<xsl:template match="*[ contains(@xsi:type, 'namedColumnsJoinType') ]">
		<xsl:text> USING (</xsl:text>
		<xsl:apply-templates select="ad:ColumnList"/>
		<xsl:text>) </xsl:text> 
	</xsl:template> 
	
	<xsl:template match="ad:ColumnList">	  
		<xsl:variable name="list">
			<xsl:for-each select="ad:ColumnName">
				<xsl:value-of select="."/>
				<xsl:text>, </xsl:text>
			</xsl:for-each>
		</xsl:variable>
		<xsl:value-of select="substring($list, 1, string-length($list)-2)"/>
	    <xsl:value-of select="$spaceCharacter"/>
	</xsl:template> 
	
	<!--+
	    | Puts out some dot-qualified name.
	    | cat.schema.tabx or cat.schema.tabx.coly.
	    | All qualification is optional.
	    +-->
	<xsl:template name="qualifiedName" >
	   <xsl:if test="@Catalog">
	        <xsl:value-of select="@Catalog"/>
			<xsl:text>.</xsl:text>
		</xsl:if>
		<xsl:if test="@Schema">
	        <xsl:value-of select="@Schema"/>
			<xsl:text>.</xsl:text>
		</xsl:if>
        <xsl:if test="@Table">
	        <xsl:value-of select="@Table"/>
			<xsl:text>.</xsl:text>
		</xsl:if>
		<xsl:value-of select="@Name"/>
	</xsl:template>	
		
	<xsl:template match="text()"/>
	
</xsl:stylesheet>
