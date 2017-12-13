<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:ims="http://www.imsglobal.org/xsd/imsccv1p1/imscp_v1p1"
    xmlns:ng="http://www.wiley.com/namespaces/ng/data"
    xmlns="http://www.w3.org/1999/xhtml"
    exclude-result-prefixes="xs ims ng"
    version="2.0">
    
    <xsl:output method="xml" encoding="UTF-8" omit-xml-declaration="yes" />
    
    <!-- PARAMS -->
    <xsl:param name="mode">aws</xsl:param><!-- relative | aws | aws_dev | aws_qa | aws_prod -->
    
    <xsl:param name="awsCloud">https://ng-wp-dev.wiley.com/ngcpp/ngcp_catalog/content/prod0000011111</xsl:param>
    <xsl:param name="awsCloud_dev">https://wpng-dev.aws.wiley.com/ngref/content/prod0000011111</xsl:param>
    <xsl:param name="awsCloud_qa">https://wpng-qa.aws.wiley.com/ngref/content/prod0000011111</xsl:param>
    <xsl:param name="awsCloud_prod">https://education.wiley.com/ngref/content/prod0000011111</xsl:param>

    <xsl:template match="/">
        {
        <xsl:apply-templates/>
        }
        <xsl:apply-templates mode="prod-toc"/>
    </xsl:template>

    <xsl:template match="ims:manifest">
        "_comment": "product",
        "id": "<xsl:value-of select="@identifier"/>",
        <xsl:apply-templates select="ims:metadata"/>
        <xsl:apply-templates select="ims:organization"/>
    </xsl:template>
    
    <xsl:template match="ims:metadata"><xsl:apply-templates select="ng:meta"/></xsl:template>
    
    <xsl:template match="ng:meta">
        <xsl:variable name="aUrl"><xsl:call-template name="getCoverImageUrlAws"/></xsl:variable>
        
        "contentMeta": {
            "shortTitle": "<xsl:value-of select="ng:shortTitle"/>",
            "title": "<xsl:value-of select="ng:title"/>",
            "author": "<xsl:value-of select="ng:author"/>, mode: <xsl:value-of select="$mode"/>",
            "edition": "<xsl:value-of select="ng:edition"/>",
            "coverImageUrl": "<xsl:value-of select="$aUrl"/>",
            "objectNameGroup": [<xsl:apply-templates select="ng:objectNameGroup"></xsl:apply-templates>]
        },
    </xsl:template>
    
    <xsl:template match="ng:objectNameGroup">
        <xsl:for-each select="ng:bucket">
        {
            "id": "<xsl:value-of select="@xml:id"/>",
            "shortTitle": "<xsl:value-of select="@shortTitle"/>",
            "title": "<xsl:value-of select="text()"/>"
        }<xsl:if test="position() lt last()">,</xsl:if>
        </xsl:for-each>
    </xsl:template>

    <xsl:template match="ims:organization">
        "itemList": [
            <xsl:for-each select="ims:item[@type='chapter']">
                <xsl:call-template name="makeChapter"/>
                <xsl:if test="position() lt last()">,</xsl:if>
            </xsl:for-each>            
        ],
        "resourceList": [
            <xsl:for-each select="ims:item[@type='prodResCollection']/ims:item[@type='mediaAsset']">
                <xsl:call-template name="makeResource-mediaAsset"/>
                <xsl:if test="position() lt last()">,</xsl:if>
            </xsl:for-each>
        ]
    </xsl:template>
    
    <xsl:template name="makeChapter">
        {
            "_comment": "chapter",
            "id": "<xsl:value-of select="@identifier"/>",
            "type": "chapter",
            "prefix": "<xsl:value-of select="ims:title/@prefix"/>",
            "title": "<xsl:value-of select="ims:title/text()"/>",
            "itemList":[
                <xsl:for-each select="ims:item[@type='section']">
                    <xsl:call-template name="makeSection"/>
                    <xsl:if test="position() lt last()">,</xsl:if>
                </xsl:for-each>                
            ],
            "resourceList":[
                <xsl:for-each select="ims:item[@type='chapResCollection']/ims:item[@type='mediaAsset']">
                    <xsl:call-template name="makeResource-mediaAsset"/>
                    <xsl:if test="position() lt last()">,</xsl:if>
                </xsl:for-each>
            ]
        }
    </xsl:template>
    
    <xsl:template name="makeSection">
        {
            "_comment": "section",
            "id": "<xsl:value-of select="@identifier"/>",
            "type": "section",
            "prefix": "<xsl:value-of select="ims:title/@prefix"/>",
            "title": "<xsl:value-of select="ims:title/text()"/>",
            "resourceList": [
                <xsl:for-each select="ims:item">
                    <xsl:choose>
                        <xsl:when test="@type = 'homeComposite'"><xsl:call-template name="makeResource-homeComposite"/></xsl:when>
                        <xsl:when test="@type = 'onlineReading'"><xsl:call-template name="makeResource-onlineReading"/></xsl:when>
                        <xsl:when test="@type = 'mediaAsset'"><xsl:call-template name="makeResource-mediaAsset"/></xsl:when>
                        <xsl:when test="@type = 'practice'"><xsl:call-template name="makeResource-practice"/></xsl:when>
                        <xsl:otherwise>{"_comment": "Resource: UNKNOWN", "type": "<xsl:value-of select="@type"/>"}</xsl:otherwise>
                    </xsl:choose>
                    
                    <xsl:if test="position() lt last()">,</xsl:if>
                </xsl:for-each>
            ]
        }
    </xsl:template>
    
    <xsl:template name="makeResource-homeComposite">
        <xsl:variable name="rTitle"><xsl:value-of select="ims:title/text()"/></xsl:variable>
        <xsl:variable name="rUrl"><xsl:call-template name="getResourceUrl"/></xsl:variable>
        <xsl:variable name="aUrl"><xsl:call-template name="getResourceUrlAws"/></xsl:variable>
        
        {
            "_comment": "Resource: Homepage Composite",
            "id": "<xsl:value-of select="@identifier"/>",
            "type": "homeComposite",
            "title": "<xsl:value-of select="$rTitle"/>",
            "url": "<xsl:value-of select="$aUrl"/>"
        }
        
        <xsl:call-template name="makeHpcResFile">
            <xsl:with-param name="fName"><xsl:value-of select="$rUrl"/></xsl:with-param>
            <xsl:with-param name="rTitle"><xsl:value-of select="$rTitle"/></xsl:with-param>
        </xsl:call-template>
    </xsl:template>
    
    <xsl:template name="makeResource-onlineReading">
        {
            "_comment": "Resource: Online Reading (epub)",
            "id": "<xsl:value-of select="@identifier"/>",
            "type": "onlineReading",
            "title": "<xsl:call-template name="getEpubResourceTitle"/>",
            "url": "<xsl:value-of select="@url"/>"
        }
    </xsl:template>
    
    
    <xsl:template name="makeResource-mediaAsset">
        <xsl:variable name="rTitle"><xsl:call-template name="getMaResourceTitle"/></xsl:variable>
        <xsl:variable name="rUrl"><xsl:call-template name="getResourceUrl"/></xsl:variable>
        <xsl:variable name="aUrl"><xsl:call-template name="getResourceUrlAws"/></xsl:variable>
        <xsl:variable name="tUrl"><xsl:call-template name="getMaResourceThumbnailUrl"/></xsl:variable>
        
        
        {
            "_comment": "Resource: Media Asset",
            "id": "<xsl:value-of select="@identifier"/>",
            "type": "mediaAsset",
            "title": "<xsl:value-of select="$rTitle"/>",
            "mediaType": <xsl:value-of select="number(@mType)"/>,
            <xsl:if test="number(@audience)">"audience": <xsl:value-of select="@audience"/>,</xsl:if>
            <xsl:if test="number(@importance)">"importance": <xsl:value-of select="@importance"/>,</xsl:if>
            <xsl:if test="string(@thumbnail) ne 'no'">"thumbnailUrl": "<xsl:value-of select="$tUrl"/>",</xsl:if>
            <xsl:if test="number(@width)">"width": <xsl:value-of select="number(@width)"/>,</xsl:if>
            <xsl:if test="number(@height)">"height": <xsl:value-of select="(@height)"/>,</xsl:if>
            <xsl:if test="string(@description)">"description": "<xsl:value-of select="normalize-space(@description)"/>",</xsl:if>
            "url": "<xsl:value-of select="$aUrl"/>"
        }
        
        <xsl:call-template name="makeMaResFile">
            <xsl:with-param name="fName"><xsl:value-of select="$rUrl"/></xsl:with-param>
            <xsl:with-param name="rTitle"><xsl:value-of select="$rTitle"/></xsl:with-param>
        </xsl:call-template>
    </xsl:template>
    
    
    <xsl:template name="makeResource-practice">
        {
        "_comment": "Resource: Practice Question",
        "id": "<xsl:value-of select="@identifier"/>",
        "type": "practice",
        "url": "<xsl:call-template name="getPracriceId" />"
        }
    </xsl:template>
    
    <xsl:template name="getResourceUrl">
        <xsl:choose>
            <xsl:when test="string(@url)">
                <xsl:value-of select="@url"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:variable name="chapId">data</xsl:variable>
                <xsl:variable name="resId"><xsl:value-of select="@identifier"/></xsl:variable>
                <xsl:variable name="resExt">html</xsl:variable>
                
                <xsl:value-of select="concat($chapId, '/', $resId, '.', $resExt)"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    
    <xsl:template name="getResourceUrlAws">
        <xsl:variable name="rUrl"><xsl:call-template name="getResourceUrl"/></xsl:variable>
        
        <xsl:choose>
            <xsl:when test="$mode = 'aws'"><xsl:value-of select="concat($awsCloud, '/', $rUrl)"/></xsl:when>
            <xsl:when test="$mode = 'aws_dev'"><xsl:value-of select="concat($awsCloud_dev, '/', $rUrl)"/></xsl:when>
            <xsl:when test="$mode = 'aws_qa'"><xsl:value-of select="concat($awsCloud_qa, '/', $rUrl)"/></xsl:when>
            <xsl:when test="$mode = 'aws_prod'"><xsl:value-of select="concat($awsCloud_prod, '/', $rUrl)"/></xsl:when>
            <xsl:otherwise><xsl:value-of select="$rUrl"/></xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    
    <xsl:template name="getCoverImageUrlAws">
        <xsl:variable name="rUrl"><xsl:value-of select="/ims:manifest/ims:metadata/ng:meta/ng:coverImage/@url"/></xsl:variable>
        
        <xsl:choose>
            <xsl:when test="$mode = 'aws'"><xsl:value-of select="concat($awsCloud, '/', $rUrl)"/></xsl:when>
            <xsl:when test="$mode = 'aws_dev'"><xsl:value-of select="concat($awsCloud_dev, '/', $rUrl)"/></xsl:when>
            <xsl:when test="$mode = 'aws_qa'"><xsl:value-of select="concat($awsCloud_qa, '/', $rUrl)"/></xsl:when>
            <xsl:when test="$mode = 'aws_prod'"><xsl:value-of select="concat($awsCloud_prod, '/', $rUrl)"/></xsl:when>
            <xsl:otherwise><xsl:value-of select="$rUrl"/></xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    
    <xsl:template name="getEpubResourceTitle">
        <xsl:choose>
            <xsl:when test="ims:title/@mode='auto'">
                <xsl:value-of select="../ims:title/text()"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:value-of select="ims:title/text()"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    
    <xsl:template name="getMaResourceTitle">
        <xsl:choose>
            <xsl:when test="starts-with(ims:title/@mode, 'auto')">
                <xsl:variable name="prefix">
                    <xsl:choose>
                        <xsl:when test="ims:title/@mode = 'auto_prod'">Prouct Level</xsl:when>
                        <xsl:when test="ims:title/@mode = 'auto_chap'">Chapter Level, <xsl:value-of select="../../ims:title/@prefix"/></xsl:when>
                        <xsl:otherwise><xsl:value-of select="../ims:title/@prefix"/></xsl:otherwise>
                    </xsl:choose>
                </xsl:variable>
                <xsl:variable name="mType">
                    <xsl:call-template name="getMaTypeName">
                        <xsl:with-param name="mType"><xsl:value-of select="@mType"/></xsl:with-param>
                    </xsl:call-template>
                </xsl:variable>
                <xsl:variable name="iCounter"><xsl:value-of select="ims:title/@counter"/></xsl:variable>
                <xsl:variable name="iAudience">
                    <xsl:choose>
                        <xsl:when test="number(@audience)"><xsl:value-of select="@audience"/></xsl:when>
                        <xsl:otherwise>1</xsl:otherwise>
                    </xsl:choose>
                </xsl:variable>
                <xsl:variable name="iImportance">
                    <xsl:choose>
                        <xsl:when test="number(@importance)"><xsl:value-of select="@importance"/></xsl:when>
                        <xsl:otherwise>1</xsl:otherwise>
                    </xsl:choose>
                </xsl:variable>
                
                <xsl:value-of select="concat($prefix, ', MA, Type ', $mType, ', Inst ', $iCounter, ', Audience=', $iAudience, ', Importance=', $iImportance)"/>
            </xsl:when>
            <xsl:otherwise><xsl:value-of select="ims:title/text()"/></xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    
    <xsl:template name="getMaResourceThumbnailUrl">
        <xsl:choose>
            <xsl:when test="@thumbnail='no'">no thumbnail</xsl:when>
            <xsl:when test="starts-with(@thumbnail, 'auto')">
                <xsl:variable name="iSize">
                    <xsl:choose>
                        <xsl:when test="@thumbnail='auto_lg'">400x300</xsl:when>
                        <xsl:when test="@thumbnail='auto_sm'">80x60</xsl:when>
                        <xsl:otherwise>264x198</xsl:otherwise>
                    </xsl:choose>
                </xsl:variable>
                <xsl:variable name="mType">
                    <xsl:call-template name="getMaTypeName">
                        <xsl:with-param name="mType"><xsl:value-of select="@mType"/></xsl:with-param>
                    </xsl:call-template>
                </xsl:variable>
                <xsl:variable name="mColors">eee/777</xsl:variable>
                
                <xsl:value-of select="concat('https://via.placeholder.com/', $iSize, '/', $mColors, '?text=', $mType)"/>
            </xsl:when>
            <xsl:otherwise><xsl:value-of select="@thumbnail"/></xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    
    
    <xsl:template name="getMaTypeName">
        <xsl:param name="mType"><xsl:value-of select="@mType"/></xsl:param>
        <xsl:choose>
            <xsl:when test="$mType = 1">Animation</xsl:when>
            <xsl:when test="$mType = 2">Video</xsl:when>
            <xsl:when test="$mType = 3">Interactivity</xsl:when>
            <xsl:when test="$mType = 4">Text</xsl:when>
            <xsl:when test="$mType = 5">Audio</xsl:when>
            <xsl:when test="$mType = 6">Reference</xsl:when>
            <xsl:when test="$mType = 7">Worksheet</xsl:when>
            <xsl:when test="$mType = 8">Dataset</xsl:when>
            <xsl:when test="$mType = 9">Document</xsl:when>
            <xsl:otherwise>Unknown</xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    
    <xsl:template name="getMaTypeColors">
        <xsl:param name="mType"><xsl:value-of select="@mType"/></xsl:param>
        <xsl:choose>
            <xsl:when test="$mType = 1">1876D3/ffffff</xsl:when><!-- Animation -->
            <xsl:when test="$mType = 2">FFC400/000000</xsl:when><!-- Video -->
            <xsl:when test="$mType = 3">DE255D/ffffff</xsl:when><!-- Interactivity -->
            <xsl:when test="$mType = 4">ccc/555</xsl:when><!-- Text -->
            <xsl:when test="$mType = 5">0A8B00/ffffff</xsl:when><!-- Audio -->
            <xsl:when test="$mType = 6">D100B9/ffffff</xsl:when><!-- Reference -->
            <xsl:when test="$mType = 7">DE3300/ffffff</xsl:when><!-- Worksheet -->
            <xsl:when test="$mType = 8">008395/ffffff</xsl:when><!-- Dataset -->
            <xsl:when test="$mType = 9">4438CC/ffffff</xsl:when><!-- Document -->
            <xsl:otherwise>ccc/555</xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    

    <!-- ////////////////////////////////// -->
    <!-- Resource Files Creation  -->
    <!-- ////////////////////////////////// -->
    
    <xsl:output name="docOutput" encoding="UTF-8" exclude-result-prefixes="ims ng" method="xhtml" omit-xml-declaration="yes" indent="no" />

    <xsl:template name="makeHpcResFile">
        <xsl:param name="fName">res-abc.html</xsl:param>
        <xsl:param name="rTitle">Default Title</xsl:param>

        <xsl:choose>
            <xsl:when test="string(@identifierref)">
                <xsl:variable name="rId"><xsl:value-of select="@identifierref"/></xsl:variable>
                <xsl:variable name="hpcNode" select="/ims:manifest/ims:resources/ims:resource[@identifier=$rId]"/>
                
                <xsl:result-document href="{$fName}" format="docOutput">
                    <xsl:text disable-output-escaping='yes'>&lt;!DOCTYPE html></xsl:text>
                    <xsl:copy-of select="$hpcNode/*"/>
                </xsl:result-document>
            </xsl:when>
            <xsl:otherwise>
                <xsl:result-document href="{$fName}" format="docOutput">
                    <xsl:text disable-output-escaping='yes'>&lt;!DOCTYPE html></xsl:text>
                    <atricle xmlns="http://www.w3.org/1999/xhtml">
                        <h1><xsl:value-of select="$rTitle"/></h1>
                    </atricle>
                </xsl:result-document>
            </xsl:otherwise>
        </xsl:choose>
            
    </xsl:template>
    
    
    <xsl:template name="makeMaResFile">
        <xsl:param name="fName">res-abc.html</xsl:param>
        <xsl:param name="rTitle">Default Title</xsl:param>
        
        <xsl:variable name="rText"><xsl:call-template name="getMaTypeName"/></xsl:variable>
        <xsl:variable name="rWidth">
            <xsl:choose>
                <xsl:when test="number(@width) and number(@height)"><xsl:value-of select="number(@width)"/></xsl:when>
                <xsl:otherwise>800</xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        <xsl:variable name="rHeight">
            <xsl:choose>
                <xsl:when test="number(@width) and number(@height)"><xsl:value-of select="number(@height)"/></xsl:when>
                <xsl:otherwise>600</xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        
        <xsl:result-document href="{$fName}"  format="docOutput">
            <xsl:text disable-output-escaping='yes'>&lt;!DOCTYPE html></xsl:text>
            <html xmlns="http://www.w3.org/1999/xhtml">
                <head>
                    <title><xsl:value-of select="$rTitle"/></title>
                    <meta http-equiv="Content-Type" content="text/html; charset=UTF-8"/>
                    <meta name="viewport" content="width=device-width, initial-scale=1.0"/>
                    <link rel="stylesheet" href="https://maxcdn.bootstrapcdn.com/bootstrap/3.3.7/css/bootstrap.min.css"
                        integrity="sha384-BVYiiSIFeK1dGmJRAkycuHAHRg32OmUcww7on3RYdg4Va+PmSTsz/K68vbdEjh4u" crossorigin="anonymous"/>
                </head>
                <body>
                    <xsl:variable name="maColors"><xsl:call-template name="getMaTypeColors"/></xsl:variable>
                    <div class="text-center"><img src="https://via.placeholder.com/{$rWidth}x{$rHeight}/{$maColors}/?text=Media+for+{$rText}" alt="{$fName}"/></div>
                    <p class="sr-only"><xsl:value-of select="$rTitle"/></p>
                </body>
            </html>
        </xsl:result-document>
    </xsl:template>
    
    
    
    <!-- ////////////////////////////////// -->
    <!-- Product Organization -->
    <!-- ////////////////////////////////// -->
    
    
        
    <xsl:template match="ims:manifest" mode="prod-toc">
        <xsl:apply-templates select="ims:organization" mode="prod-toc"/>
    </xsl:template>
    
    <xsl:template match="ims:organization" mode="prod-toc">
        <xsl:param name="tName">index.html</xsl:param>
        <xsl:param name="tTitle"><xsl:value-of select="/ims:manifest/ims:metadata/ng:meta/ng:title"></xsl:value-of></xsl:param>
        
        <xsl:result-document href="{$tName}" method="html">
            <xsl:text disable-output-escaping='yes'>&lt;!DOCTYPE html></xsl:text>
            <html xmlns="http://www.w3.org/1999/xhtml">
                <head>
                    <title><xsl:value-of select="$tTitle"/></title>
                    <meta http-equiv="Content-Type" content="text/html; charset=UTF-8"/>
                    <meta name="viewport" content="width=device-width, initial-scale=1.0"/>
                    <link rel="stylesheet" href="https://maxcdn.bootstrapcdn.com/bootstrap/3.3.7/css/bootstrap.min.css"
                            integrity="sha384-BVYiiSIFeK1dGmJRAkycuHAHRg32OmUcww7on3RYdg4Va+PmSTsz/K68vbdEjh4u" crossorigin="anonymous"/>
                </head>
                <body>
                    <div class="container">
                        <a name="root"/>
                        <h1>[PRODUCT] <xsl:value-of select="$tTitle"/></h1>
                        <ul>
                            <xsl:for-each select="ims:item[@type='chapter']">
                                <li>
                                    <a href="#{generate-id()}"><xsl:value-of select="concat(ims:title/@prefix, ', ', ims:title/text())"/></a>
                                    <ul>
                                        <xsl:for-each select="ims:item">
                                            <li><a href="#{generate-id()}"><xsl:value-of select="concat(ims:title/@prefix, ', ', ims:title/text())"/></a></li>
                                        </xsl:for-each>
                                    </ul>
                                </li>
                            </xsl:for-each>
                            <li><a href="#{generate-id(ims:item[@type='prodResCollection'][1])}">Product Level Resources</a></li>
                        </ul>
                        
                        <hr/>
                        
                        <xsl:apply-templates mode="prod-toc"/>
                    </div>
                </body>
            </html>
        </xsl:result-document>
        
    </xsl:template>
    
    
    <xsl:template match="ims:item[@type = 'chapter']" mode="prod-toc">
        <a name="{generate-id(.)}"/>
        <h2><xsl:value-of select="concat('[CHAPTER] ', ims:title/@prefix, ', ', ims:title/text())"/></h2>
        
        <xsl:apply-templates select="ims:item[@type='section']" mode="prod-toc"/>
        <xsl:apply-templates select="ims:item[@type='chapResCollection']" mode="prod-toc"/>
    </xsl:template>
    
    <xsl:template match="ims:item[@type='prodResCollection']" mode="prod-toc">
        <a name="{generate-id(.)}"/>
        
        <div class="panel panel-danger">
            <div class="panel-heading">
                <h3 class="panel-title"><xsl:value-of select="ims:title"/></h3>
            </div>
            <div class="panel-body">
                <div><strong>TOC: </strong>&#xa0;<a href="#root">^</a></div>
                
                <table class="table table-bordered table-hover">
                    <thead>
                        <tr>
                            <th>#</th>
                            <th>ID</th>
                            <th>Res Type</th>
                            <th>Res Title</th>
                            <th>Media Type</th>
                            <th>Metadata</th>
                            <th>Thumbnail</th>
                        </tr>
                    </thead>
                    <tbody>
                        
                        <xsl:apply-templates select="ims:item" mode="prod-toc"/>
                        
                    </tbody>
                </table>
            </div>
        </div>
    </xsl:template>
    
    <xsl:template match="ims:item[@type='chapResCollection']" mode="prod-toc">
        <a name="{generate-id(.)}"/>
        
        <div class="panel panel-warning">
            <div class="panel-heading">
                <h3 class="panel-title"><xsl:value-of select="concat(ims:title/@prefix, ', ', ims:title/text())"/></h3>
            </div>
            <div class="panel-body">
                <div><strong>TOC: </strong>&#xa0;<a href="#root">^</a></div>
                <table class="table table-bordered table-hover">
                    <thead>
                        <tr>
                            <th>#</th>
                            <th>ID</th>
                            <th>Res Type</th>
                            <th>Res Title</th>
                            <th>Media Type</th>
                            <th>Metadata</th>
                            <th>Thumbnail</th>
                        </tr>
                    </thead>
                    <tbody>
                        
                        <xsl:apply-templates select="ims:item" mode="prod-toc"/>
                        
                    </tbody>
                </table>
            </div>
        </div>
    </xsl:template>
    
    
    
    <xsl:template name="getHash4Section">
        <xsl:variable name="prodId"><xsl:value-of select="/ims:manifest/@identifier"/></xsl:variable>
        <xsl:variable name="chapId"><xsl:value-of select="ancestor::ims:item[@type='chapter']/@identifier"/></xsl:variable>
        <xsl:variable name="secId"><xsl:value-of select="@identifier"/></xsl:variable>
        
        <xsl:value-of select="concat('#prod/', $prodId, '/chap/', $chapId, '/sec/', $secId)"/>
    </xsl:template>
    
    <xsl:template match="ims:item[@type = 'section']" mode="prod-toc">
        <a name="{generate-id(.)}"/>
        <div class="panel panel-primary">
            <div class="panel-heading">
                <h3 class="panel-title"><xsl:value-of select="concat('[SECTION] ', ims:title/@prefix, ', ', ims:title/text())"/></h3>
            </div>
            <div class="panel-body">
                <div><strong>TOC: </strong>&#xa0;<a href="#root">^</a></div>
                <div><strong>id:</strong>&#xa0;<xsl:value-of select="@identifier"/></div>
                <div><strong>Title:</strong>&#xa0;<xsl:value-of select="ims:title"/></div>
                <div><strong>Prefix:</strong>&#xa0;<xsl:value-of select="ims:title/@prefix"/></div>
                
                <div class="alert alert-info"><strong>Hash Key:</strong>&#xa0;<xsl:call-template name="getHash4Section"/></div>
                
                <h4>Section Resources</h4>
                <table class="table table-bordered table-hover">
                    <thead>
                        <tr>
                            <th>#</th>
                            <th>ID</th>
                            <th>Res Type</th>
                            <th>Res Title</th>
                            <th>Media Type</th>
                            <th>Metadata</th>
                            <th>Thumbnail</th>
                        </tr>
                    </thead>
                    <tbody>
                        
                        <xsl:apply-templates select="ims:item" mode="prod-toc"/>
                        
                    </tbody>
                </table>
                
            </div>
        </div>
    </xsl:template>
    
    <xsl:template match="ims:item[@type = 'homeComposite']" mode="prod-toc">
        <xsl:variable name="aUrl"><xsl:call-template name="getResourceUrlAws"/></xsl:variable>
        
        <tr class="warning">
            <td><xsl:call-template name="getResPosition"/></td>
            <td><xsl:value-of select="@identifier"/></td>
            <td><xsl:value-of select="@type"/></td>
            <td><a href="{$aUrl}"><xsl:value-of select="ims:title"/></a></td>
            <td>n/a</td>
            <td/><!-- Meatdata -->
            <td>n/a</td>
        </tr>
    </xsl:template>
    
    <xsl:template match="ims:item[@type = 'onlineReading']" mode="prod-toc">
        <xsl:variable name="aUrl"><xsl:call-template name="getCoverImageUrlAws"/></xsl:variable>
        
        <tr class="success">
            <td><xsl:call-template name="getResPosition"/></td>
            <td><xsl:value-of select="@identifier"/></td>
            <td><xsl:value-of select="@type"/></td>
            <td><xsl:call-template name="getEpubResourceTitle"/></td>
            <td>n/a</td>
            <td>n/a</td><!-- Meatdata -->
            <td>
                <img src="{$aUrl}" alt="Cover Image 85x113"/>
            </td>
        </tr>
    </xsl:template>
    
    <xsl:template match="ims:item[@type = 'mediaAsset']" mode="prod-toc">
        <xsl:variable name="aUrl"><xsl:call-template name="getResourceUrlAws"/></xsl:variable>
        
        <tr>
            <td><xsl:call-template name="getResPosition"/></td>
            <td><xsl:value-of select="@identifier"/></td>
            <td><xsl:value-of select="@type"/></td>
            <td><a href="{$aUrl}"><xsl:call-template name="getMaResourceTitle"/></a></td>
            <td><xsl:call-template name="getMaTypeName"/></td>
            <td>
                <ul>
                    <li class="text-nowrap">Audience:
                        <xsl:choose>
                            <xsl:when test="number(@audience) = 2">[2]Instructor</xsl:when>
                            <xsl:otherwise>[1]Student</xsl:otherwise>
                        </xsl:choose>
                    </li>
                    <li class="text-nowrap">
                        Importance: 
                        <xsl:choose>
                            <xsl:when test="number(@importance) = 2">[2]Secondary</xsl:when>
                            <xsl:otherwise>[1]Primary</xsl:otherwise>
                        </xsl:choose>                        
                    </li>
                    <li class="text-nowrap">
                        width: 
                        <xsl:choose>
                            <xsl:when test="number(@width)"><xsl:value-of select="@width"/></xsl:when>
                            <xsl:otherwise>-</xsl:otherwise>
                        </xsl:choose>                        
                    </li>
                    <li class="text-nowrap">
                        height: 
                        <xsl:choose>
                            <xsl:when test="number(@height)"><xsl:value-of select="@height"/></xsl:when>
                            <xsl:otherwise>-</xsl:otherwise>
                        </xsl:choose>                        
                    </li>
                    <li class="text-nowrap">
                        description: 
                        <xsl:choose>
                            <xsl:when test="string(@description)">
                                <span title="{normalize-space(@description)}">provided</span>
                            </xsl:when>
                            <xsl:otherwise>-</xsl:otherwise>
                        </xsl:choose>                        
                    </li>
                </ul>                
            </td>
            <td>
                <xsl:choose>
                    <xsl:when test="string(@thumbnail) ne 'no'">
                        <xsl:variable name="tUrl"><xsl:call-template name="getMaResourceThumbnailUrl"/></xsl:variable>
                        <img src="{$tUrl}" alt="Thumbnail for {@identifier}" title="Thumbnail for {@identifier}"/>
                    </xsl:when>
                    <xsl:otherwise>n/a</xsl:otherwise>
                </xsl:choose>
            </td>
        </tr>
    </xsl:template>
    
    <xsl:template name="getPracriceTitle">
        <xsl:variable name="curId"><xsl:value-of select="generate-id(.)"/></xsl:variable>
        <xsl:for-each select="../ims:item[@type = 'practice']">
            <xsl:if test="$curId = generate-id(.)"><xsl:value-of select="concat('Question ', position())"/></xsl:if>
        </xsl:for-each>
    </xsl:template>
    
    <xsl:template name="getPracriceId">
       <xsl:choose>
           <xsl:when test="$mode = 'aws_dev' and string(@qCardId_dev)">
               <xsl:value-of select="@qCardId_dev"/>
           </xsl:when>
           <xsl:when test="$mode = 'aws_qa' and string(@qCardId_qa)">
               <xsl:value-of select="@qCardId_qa"/>
           </xsl:when>
           <xsl:when test="$mode = 'aws_prod' and string(@qCardId)">
               <xsl:value-of select="@qCardId"/>
           </xsl:when>
           <xsl:otherwise>undefined</xsl:otherwise>
       </xsl:choose>
    </xsl:template>
    
    <xsl:template name="getPracriceLauncher">
        <xsl:variable name="qCardId"><xsl:call-template name="getPracriceId"/></xsl:variable>
        
        <xsl:choose>
            <xsl:when test="$mode = 'aws_dev'">
                <xsl:value-of select="concat('https://dev.api.wiley.com/was/v1/frontpage/questionView?qCardId=', $qCardId)"/>
            </xsl:when>
            <xsl:when test="$mode = 'aws_qa'">
                <xsl:value-of select="concat('https://dev-qa.api.wiley.com/was/v1/frontpage/questionView?qCardId=', $qCardId)"/>
            </xsl:when>
            <xsl:when test="$mode = 'aws_prod'">
                <xsl:value-of select="concat('https://api.wiley.com/was/v1/frontpage/questionView?qCardId=', $qCardId)"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:value-of select="$qCardId"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    
    <xsl:template match="ims:item[@type = 'practice']" mode="prod-toc">
        <xsl:variable name="practiceLauncher">
            <xsl:call-template name="getPracriceLauncher"/>
        </xsl:variable>
        
        <tr class="info">
            <td><xsl:call-template name="getResPosition"/></td>
            <td><xsl:value-of select="@identifier"/></td>
            <td><xsl:value-of select="@type"/></td>
            <td><a href="{$practiceLauncher}" target="_blank"><xsl:call-template name="getPracriceTitle"/></a></td>
            <td>n/a</td>
            <td>n/a</td><!-- Metadata -->
            <td>n/a</td>
        </tr>
    </xsl:template>
    
    <xsl:template name="getResPosition">
        <xsl:variable name="curId"><xsl:value-of select="generate-id(.)"/></xsl:variable>
        <xsl:for-each select="../ims:item">
            <xsl:if test="$curId = generate-id(.)"><xsl:value-of select="position()"/></xsl:if>
        </xsl:for-each>
    </xsl:template>
    
    <xsl:template match="*" >
        <xsl:apply-templates mode="prod-toc"/>
    </xsl:template>

    
    
    <!-- DEBUG markup 
    <xsl:template match="*">
        
        <xsl:choose>
            <xsl:when test="$wDebug = 'true'">
                <span class="text-danger">
                    <xsl:value-of select="concat('&lt;', local-name(.), '&gt;')"/>
                    <xsl:apply-templates/>
                    <xsl:value-of select="concat('&lt;/', local-name(.), '&gt;')"/>
                </span>
            </xsl:when>
            <xsl:otherwise>
                <xsl:apply-templates/>
            </xsl:otherwise>
        </xsl:choose>        
        
    </xsl:template>
    -->
    
    
    
</xsl:stylesheet>