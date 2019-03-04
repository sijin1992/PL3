<GameFile>
  <PropertyGroup Name="EnemyLayer" Type="Layer" ID="6b576166-f400-4f90-96d4-f40bbbfc3508" Version="3.10.0.0" />
  <Content ctype="GameProjectContent">
    <Content>
      <Animation Duration="20" Speed="1.0000">
        <Timeline ActionTag="-1051944743" Property="Position">
          <PointFrame FrameIndex="0" X="670.5991" Y="730.0000">
            <EasingData Type="0" />
          </PointFrame>
          <PointFrame FrameIndex="20" X="620.5983" Y="730.0000">
            <EasingData Type="0" />
          </PointFrame>
        </Timeline>
        <Timeline ActionTag="-1051944743" Property="Scale">
          <ScaleFrame FrameIndex="0" X="1.0000" Y="1.0000">
            <EasingData Type="0" />
          </ScaleFrame>
          <ScaleFrame FrameIndex="20" X="1.0000" Y="1.0000">
            <EasingData Type="0" />
          </ScaleFrame>
        </Timeline>
        <Timeline ActionTag="-1051944743" Property="RotationSkew">
          <ScaleFrame FrameIndex="0" X="0.0000" Y="0.0000">
            <EasingData Type="0" />
          </ScaleFrame>
          <ScaleFrame FrameIndex="20" X="0.0000" Y="0.0000">
            <EasingData Type="0" />
          </ScaleFrame>
        </Timeline>
        <Timeline ActionTag="-1051944743" Property="Alpha">
          <IntFrame FrameIndex="0" Value="0">
            <EasingData Type="0" />
          </IntFrame>
          <IntFrame FrameIndex="20" Value="255">
            <EasingData Type="0" />
          </IntFrame>
        </Timeline>
      </Animation>
      <ObjectData Name="Layer" Tag="940" ctype="GameLayerObjectData">
        <Size X="1136.0000" Y="768.0000" />
        <Children>
          <AbstractNodeData Name="star_node" ActionTag="-190409891" Tag="900" IconVisible="True" RightMargin="1136.0000" TopMargin="768.0000" ctype="SingleNodeObjectData">
            <Size X="0.0000" Y="0.0000" />
            <AnchorPoint />
            <Position />
            <Scale ScaleX="1.0000" ScaleY="1.0000" />
            <CColor A="255" R="255" G="255" B="255" />
            <PrePosition />
            <PreSize X="0.0000" Y="0.0000" />
          </AbstractNodeData>
          <AbstractNodeData Name="empty" ActionTag="1081368692" VisibleForFrame="False" Tag="175" IconVisible="True" LeftMargin="568.0000" RightMargin="568.0000" TopMargin="384.0000" BottomMargin="384.0000" StretchWidthEnable="False" StretchHeightEnable="False" InnerActionSpeed="1.0000" CustomSizeEnabled="False" ctype="ProjectNodeObjectData">
            <Size X="0.0000" Y="0.0000" />
            <AnchorPoint />
            <Position X="568.0000" Y="384.0000" />
            <Scale ScaleX="1.0000" ScaleY="1.0000" />
            <CColor A="255" R="255" G="255" B="255" />
            <PrePosition X="0.5000" Y="0.5000" />
            <PreSize X="0.0000" Y="0.0000" />
            <FileData Type="Normal" Path="ColonizeScene/empty.csd" Plist="" />
          </AbstractNodeData>
          <AbstractNodeData Name="prompt_bottom_15" ActionTag="-1935872453" Tag="947" IconVisible="False" LeftMargin="66.8417" RightMargin="624.1583" TopMargin="153.5350" BottomMargin="547.4650" ctype="SpriteObjectData">
            <Size X="445.0000" Y="67.0000" />
            <AnchorPoint ScaleX="0.5000" ScaleY="0.5000" />
            <Position X="289.3417" Y="580.9650" />
            <Scale ScaleX="1.0000" ScaleY="1.0000" />
            <CColor A="255" R="255" G="255" B="255" />
            <PrePosition X="0.2547" Y="0.7565" />
            <PreSize X="0.3917" Y="0.0872" />
            <FileData Type="Normal" Path="Common/newUI/prompt_bottom.png" Plist="" />
            <BlendFunc Src="1" Dst="771" />
          </AbstractNodeData>
          <AbstractNodeData Name="my_slave" ActionTag="2015041241" Tag="946" RotationSkewX="8.0000" IconVisible="False" PositionPercentXEnabled="True" PositionPercentYEnabled="True" LeftMargin="76.7936" RightMargin="937.2064" TopMargin="158.8749" BottomMargin="564.1251" FontSize="30" LabelText="我的奴隶" TouchScaleChangeAble="True" HorizontalAlignmentType="HT_Center" VerticalAlignmentType="VT_Center" OutlineSize="2" ShadowOffsetX="0.5000" ShadowOffsetY="0.5000" ctype="TextObjectData">
            <Size X="122.0000" Y="45.0000" />
            <AnchorPoint ScaleY="0.4977" />
            <Position X="76.7936" Y="586.5216" />
            <Scale ScaleX="1.0000" ScaleY="1.0000" />
            <CColor A="255" R="255" G="249" B="223" />
            <PrePosition X="0.0676" Y="0.7637" />
            <PreSize X="0.1074" Y="0.0586" />
            <FontResource Type="Normal" Path="fonts/cuyabra.ttf" Plist="" />
            <OutlineColor A="255" R="10" G="88" B="242" />
            <ShadowColor A="255" R="255" G="249" B="223" />
          </AbstractNodeData>
          <AbstractNodeData Name="my_slave_ins" ActionTag="53988854" Tag="945" IconVisible="False" PositionPercentXEnabled="True" PositionPercentYEnabled="True" LeftMargin="80.3152" RightMargin="996.6848" TopMargin="194.8669" BottomMargin="544.1331" FontSize="19" LabelText="奴隶的" TouchScaleChangeAble="True" HorizontalAlignmentType="HT_Center" VerticalAlignmentType="VT_Center" OutlineSize="2" ShadowOffsetX="0.5000" ShadowOffsetY="0.5000" ctype="TextObjectData">
            <Size X="59.0000" Y="29.0000" />
            <AnchorPoint ScaleY="0.4977" />
            <Position X="80.3152" Y="558.5664" />
            <Scale ScaleX="1.0000" ScaleY="1.0000" />
            <CColor A="255" R="162" G="157" B="134" />
            <PrePosition X="0.0707" Y="0.7273" />
            <PreSize X="0.0519" Y="0.0378" />
            <FontResource Type="Normal" Path="fonts/cuyabra.ttf" Plist="" />
            <OutlineColor A="255" R="10" G="88" B="242" />
            <ShadowColor A="255" R="162" G="157" B="134" />
          </AbstractNodeData>
          <AbstractNodeData Name="right_bottom_60" ActionTag="1356453502" UserData="top" Tag="959" IconVisible="False" LeftMargin="-0.5205" RightMargin="0.5205" TopMargin="0.7111" BottomMargin="682.2889" FlipX="True" ctype="SpriteObjectData">
            <Size X="1136.0000" Y="85.0000" />
            <AnchorPoint ScaleX="1.0000" ScaleY="1.0000" />
            <Position X="1135.4795" Y="767.2889" />
            <Scale ScaleX="1.0000" ScaleY="0.8200" />
            <CColor A="255" R="255" G="255" B="255" />
            <PrePosition X="0.9995" Y="0.9991" />
            <PreSize X="1.0000" Y="0.1107" />
            <FileData Type="Normal" Path="Common/newUI/bottom_top03.png" Plist="" />
            <BlendFunc Src="1" Dst="771" />
          </AbstractNodeData>
          <AbstractNodeData Name="chat_bottom" ActionTag="1120917745" Tag="944" IconVisible="False" LeftMargin="65.8815" RightMargin="614.1185" TopMargin="654.5555" BottomMargin="71.4445" LeftEage="150" RightEage="150" TopEage="11" BottomEage="11" Scale9OriginX="150" Scale9OriginY="11" Scale9Width="40" Scale9Height="14" ctype="ImageViewObjectData">
            <Size X="456.0000" Y="42.0000" />
            <AnchorPoint ScaleY="0.5000" />
            <Position X="65.8815" Y="92.4445" />
            <Scale ScaleX="1.0000" ScaleY="1.0000" />
            <CColor A="255" R="255" G="255" B="255" />
            <PrePosition X="0.0580" Y="0.1204" />
            <PreSize X="0.4014" Y="0.0547" />
            <FileData Type="Normal" Path="CityScene/ui3/image_chatdown.png" Plist="" />
          </AbstractNodeData>
          <AbstractNodeData Name="btn_chat" ActionTag="956312967" Tag="943" IconVisible="False" LeftMargin="71.0564" RightMargin="1007.9436" TopMargin="660.3730" BottomMargin="74.6270" TouchEnable="True" FontSize="14" Scale9Enable="True" LeftEage="15" RightEage="15" TopEage="11" BottomEage="11" Scale9OriginX="15" Scale9OriginY="11" Scale9Width="6" Scale9Height="9" ShadowOffsetX="2.0000" ShadowOffsetY="-2.0000" ctype="ButtonObjectData">
            <Size X="57.0000" Y="33.0000" />
            <AnchorPoint ScaleX="0.5000" ScaleY="0.5000" />
            <Position X="99.5564" Y="91.1270" />
            <Scale ScaleX="1.0000" ScaleY="1.0000" />
            <CColor A="255" R="255" G="255" B="255" />
            <PrePosition X="0.0876" Y="0.1187" />
            <PreSize X="0.0502" Y="0.0430" />
            <TextColor A="255" R="65" G="65" B="70" />
            <DisabledFileData Type="Default" Path="Default/Button_Disable.png" Plist="" />
            <PressedFileData Type="Normal" Path="Common/newUI/zm_chat_icon_light.png" Plist="" />
            <NormalFileData Type="Normal" Path="Common/newUI/zm_chat_icon.png" Plist="" />
            <OutlineColor A="255" R="255" G="0" B="0" />
            <ShadowColor A="255" R="110" G="110" B="110" />
          </AbstractNodeData>
          <AbstractNodeData Name="di_text" ActionTag="2039906553" Tag="219" IconVisible="False" LeftMargin="131.3252" RightMargin="926.6748" TopMargin="666.0600" BottomMargin="72.9400" TouchEnable="True" FontSize="19" LabelText="文字文字" ShadowOffsetX="0.5000" ShadowOffsetY="0.5000" ctype="TextObjectData">
            <Size X="78.0000" Y="29.0000" />
            <AnchorPoint ScaleY="0.5000" />
            <Position X="131.3252" Y="87.4400" />
            <Scale ScaleX="1.0000" ScaleY="1.0000" />
            <CColor A="255" R="255" G="255" B="255" />
            <PrePosition X="0.1156" Y="0.1139" />
            <PreSize X="0.0687" Y="0.0378" />
            <FontResource Type="Normal" Path="fonts/cuyabra.ttf" Plist="" />
            <OutlineColor A="255" R="255" G="0" B="0" />
            <ShadowColor A="255" R="255" G="255" B="255" />
          </AbstractNodeData>
          <AbstractNodeData Name="shuaxin_di" ActionTag="-1375972610" Tag="100" IconVisible="False" LeftMargin="988.8842" RightMargin="101.1157" TopMargin="627.9881" BottomMargin="94.0119" ctype="SpriteObjectData">
            <Size X="96.0000" Y="85.0000" />
            <AnchorPoint ScaleX="0.5000" ScaleY="0.5000" />
            <Position X="1011.8842" Y="117.0119" />
            <Scale ScaleX="1.0000" ScaleY="1.0000" />
            <CColor A="255" R="255" G="255" B="255" />
            <PrePosition X="0.8907" Y="0.1524" />
            <PreSize X="0.0405" Y="0.0599" />
            <FileData Type="Normal" Path="StarOccupationLayer/ui/gn_case.png" Plist="" />
            <BlendFunc Src="1" Dst="771" />
          </AbstractNodeData>
          <AbstractNodeData Name="zhua_di" ActionTag="-1999168166" Tag="99" IconVisible="False" LeftMargin="907.0106" RightMargin="182.9894" TopMargin="583.2308" BottomMargin="138.7692" ctype="SpriteObjectData">
            <Size X="96.0000" Y="85.0000" />
            <AnchorPoint ScaleX="0.5000" ScaleY="0.5000" />
            <Position X="930.0106" Y="161.7692" />
            <Scale ScaleX="1.0000" ScaleY="1.0000" />
            <CColor A="255" R="255" G="255" B="255" />
            <PrePosition X="0.8187" Y="0.2106" />
            <PreSize X="0.0405" Y="0.0599" />
            <FileData Type="Normal" Path="StarOccupationLayer/ui/gn_case.png" Plist="" />
            <BlendFunc Src="1" Dst="771" />
          </AbstractNodeData>
          <AbstractNodeData Name="icon_dbzd_118" ActionTag="-123452160" Tag="98" IconVisible="False" LeftMargin="902.5464" RightMargin="180.4536" TopMargin="575.7657" BottomMargin="136.2343" ctype="SpriteObjectData">
            <Size X="53.0000" Y="56.0000" />
            <AnchorPoint ScaleX="0.5000" ScaleY="0.5000" />
            <Position X="929.0464" Y="164.2343" />
            <Scale ScaleX="1.0000" ScaleY="1.0000" />
            <CColor A="255" R="255" G="255" B="255" />
            <PrePosition X="0.8178" Y="0.2138" />
            <PreSize X="0.0467" Y="0.0729" />
            <FileData Type="Normal" Path="Common/newUI/icon_zb.png" Plist="" />
            <BlendFunc Src="1" Dst="771" />
          </AbstractNodeData>
          <AbstractNodeData Name="jjc_sx_120" ActionTag="654789433" Tag="96" IconVisible="False" LeftMargin="981.4506" RightMargin="86.5493" TopMargin="619.7624" BottomMargin="84.2376" ctype="SpriteObjectData">
            <Size X="68.0000" Y="64.0000" />
            <AnchorPoint ScaleX="0.5000" ScaleY="0.5000" />
            <Position X="1015.4506" Y="116.2376" />
            <Scale ScaleX="0.8700" ScaleY="0.8700" />
            <CColor A="255" R="255" G="255" B="255" />
            <PrePosition X="0.8939" Y="0.1514" />
            <PreSize X="0.0599" Y="0.0833" />
            <FileData Type="Normal" Path="Common/newUI/jjc_sx.png" Plist="" />
            <BlendFunc Src="1" Dst="771" />
          </AbstractNodeData>
          <AbstractNodeData Name="shuaxin_text" ActionTag="2139089886" Tag="90" IconVisible="False" LeftMargin="995.7053" RightMargin="105.2947" TopMargin="675.1005" BottomMargin="68.8995" FontSize="16" LabelText="刷新" ShadowOffsetX="0.5000" ShadowOffsetY="0.5000" ctype="TextObjectData">
            <Size X="35.0000" Y="24.0000" />
            <AnchorPoint ScaleX="0.5000" ScaleY="0.5000" />
            <Position X="1013.2053" Y="80.8995" />
            <Scale ScaleX="1.0000" ScaleY="1.0000" />
            <CColor A="255" R="204" G="205" B="205" />
            <PrePosition X="0.8919" Y="0.1053" />
            <PreSize X="0.0308" Y="0.0313" />
            <FontResource Type="Normal" Path="fonts/cuyabra.ttf" Plist="" />
            <OutlineColor A="255" R="255" G="0" B="0" />
            <ShadowColor A="255" R="204" G="205" B="205" />
          </AbstractNodeData>
          <AbstractNodeData Name="zhua_text" ActionTag="115493768" Tag="92" IconVisible="False" LeftMargin="912.4777" RightMargin="188.5223" TopMargin="625.0399" BottomMargin="118.9601" FontSize="16" LabelText="抓捕" ShadowOffsetX="0.5000" ShadowOffsetY="0.5000" ctype="TextObjectData">
            <Size X="35.0000" Y="24.0000" />
            <AnchorPoint ScaleX="0.5000" ScaleY="0.5000" />
            <Position X="929.9777" Y="130.9601" />
            <Scale ScaleX="1.0000" ScaleY="1.0000" />
            <CColor A="255" R="204" G="205" B="205" />
            <PrePosition X="0.8186" Y="0.1705" />
            <PreSize X="0.0308" Y="0.0313" />
            <FontResource Type="Normal" Path="fonts/cuyabra.ttf" Plist="" />
            <OutlineColor A="255" R="255" G="0" B="0" />
            <ShadowColor A="255" R="204" G="205" B="205" />
          </AbstractNodeData>
          <AbstractNodeData Name="shuaxin" ActionTag="-532195364" Alpha="0" Tag="93" IconVisible="False" LeftMargin="982.4419" RightMargin="90.5581" TopMargin="620.5267" BottomMargin="84.4733" TouchEnable="True" Scale9Width="46" Scale9Height="46" ctype="ImageViewObjectData">
            <Size X="63.0000" Y="63.0000" />
            <AnchorPoint ScaleX="0.5000" ScaleY="0.5000" />
            <Position X="1013.9419" Y="115.9733" />
            <Scale ScaleX="1.0000" ScaleY="1.0000" />
            <CColor A="255" R="255" G="255" B="255" />
            <PrePosition X="0.8926" Y="0.1510" />
            <PreSize X="0.0555" Y="0.0820" />
            <FileData Type="Default" Path="Default/ImageFile.png" Plist="" />
          </AbstractNodeData>
          <AbstractNodeData Name="zhua" ActionTag="1973509109" Alpha="0" Tag="95" IconVisible="False" LeftMargin="899.8607" RightMargin="173.1393" TopMargin="573.2665" BottomMargin="131.7335" TouchEnable="True" Scale9Width="46" Scale9Height="46" ctype="ImageViewObjectData">
            <Size X="63.0000" Y="63.0000" />
            <AnchorPoint ScaleX="0.5000" ScaleY="0.5000" />
            <Position X="931.3607" Y="163.2335" />
            <Scale ScaleX="1.0000" ScaleY="1.0000" />
            <CColor A="255" R="255" G="255" B="255" />
            <PrePosition X="0.8199" Y="0.2125" />
            <PreSize X="0.0555" Y="0.0820" />
            <FileData Type="Default" Path="Default/ImageFile.png" Plist="" />
          </AbstractNodeData>
          <AbstractNodeData Name="close" ActionTag="-2031663713" UserData="righttop" Tag="956" IconVisible="False" LeftMargin="1014.7489" RightMargin="11.2511" BottomMargin="692.0000" TouchEnable="True" FontSize="14" LeftEage="15" RightEage="15" TopEage="11" BottomEage="11" Scale9OriginX="15" Scale9OriginY="11" Scale9Width="80" Scale9Height="54" ShadowOffsetX="2.0000" ShadowOffsetY="-2.0000" ctype="ButtonObjectData">
            <Size X="110.0000" Y="76.0000" />
            <AnchorPoint ScaleX="0.5000" ScaleY="0.5000" />
            <Position X="1069.7489" Y="730.0000" />
            <Scale ScaleX="1.0000" ScaleY="1.0000" />
            <CColor A="255" R="255" G="255" B="255" />
            <PrePosition X="0.9417" Y="0.9505" />
            <PreSize X="0.0968" Y="0.0990" />
            <TextColor A="255" R="65" G="65" B="70" />
            <DisabledFileData Type="Default" Path="Default/Button_Disable.png" Plist="" />
            <PressedFileData Type="Normal" Path="Common/newUI/button_back_light.png" Plist="" />
            <NormalFileData Type="Normal" Path="Common/newUI/button_back.png" Plist="" />
            <OutlineColor A="255" R="255" G="0" B="0" />
            <ShadowColor A="255" R="110" G="110" B="110" />
          </AbstractNodeData>
          <AbstractNodeData Name="info_node" ActionTag="710555987" UserData="lefttop" Tag="942" IconVisible="True" RightMargin="1136.0000" TopMargin="768.0000" ctype="SingleNodeObjectData">
            <Size X="0.0000" Y="0.0000" />
            <AnchorPoint />
            <Position />
            <Scale ScaleX="1.0000" ScaleY="1.0000" />
            <CColor A="255" R="255" G="255" B="255" />
            <PrePosition />
            <PreSize X="0.0000" Y="0.0000" />
          </AbstractNodeData>
          <AbstractNodeData Name="you" ActionTag="-1051944743" Alpha="0" UserData="righttop" Tag="948" IconVisible="True" LeftMargin="670.5991" RightMargin="465.4009" TopMargin="38.0000" BottomMargin="730.0000" ctype="SingleNodeObjectData">
            <Size X="0.0000" Y="0.0000" />
            <Children>
              <AbstractNodeData Name="st_touch" ActionTag="-382256546" Alpha="0" Tag="949" IconVisible="False" LeftMargin="184.3626" RightMargin="-343.9797" TopMargin="-23.8976" BottomMargin="-22.1024" TouchEnable="True" Scale9Width="46" Scale9Height="46" ctype="ImageViewObjectData">
                <Size X="159.6171" Y="46.0000" />
                <AnchorPoint ScaleX="0.5000" ScaleY="0.5000" />
                <Position X="264.1711" Y="0.8976" />
                <Scale ScaleX="1.0000" ScaleY="1.0000" />
                <CColor A="255" R="255" G="255" B="255" />
                <PrePosition />
                <PreSize X="0.0000" Y="0.0000" />
                <FileData Type="Default" Path="Default/ImageFile.png" Plist="" />
              </AbstractNodeData>
              <AbstractNodeData Name="line_fg01_47" ActionTag="550426907" Tag="950" IconVisible="False" LeftMargin="182.2749" RightMargin="-183.2749" TopMargin="-25.0743" BottomMargin="-23.9257" ctype="SpriteObjectData">
                <Size X="1.0000" Y="49.0000" />
                <AnchorPoint ScaleX="0.5000" ScaleY="0.5000" />
                <Position X="182.7749" Y="0.5743" />
                <Scale ScaleX="1.0000" ScaleY="1.0000" />
                <CColor A="255" R="255" G="255" B="255" />
                <PrePosition />
                <PreSize X="0.0000" Y="0.0000" />
                <FileData Type="Normal" Path="Common/newUI/line_fg01.png" Plist="" />
                <BlendFunc Src="1" Dst="771" />
              </AbstractNodeData>
              <AbstractNodeData Name="jdt_bottom02_53" Visible="False" ActionTag="-1301704406" Tag="951" IconVisible="False" LeftMargin="192.7691" RightMargin="-291.7691" TopMargin="4.5860" BottomMargin="-22.5860" ctype="SpriteObjectData">
                <Size X="99.0000" Y="18.0000" />
                <AnchorPoint ScaleX="0.5000" ScaleY="0.5000" />
                <Position X="242.2691" Y="-13.5860" />
                <Scale ScaleX="1.0000" ScaleY="1.0000" />
                <CColor A="255" R="255" G="255" B="255" />
                <PrePosition />
                <PreSize X="0.0000" Y="0.0000" />
                <FileData Type="Normal" Path="Common/newUI/jdt_bottom02.png" Plist="" />
                <BlendFunc Src="1" Dst="771" />
              </AbstractNodeData>
              <AbstractNodeData Name="progress" ActionTag="1089305911" Tag="952" IconVisible="False" LeftMargin="192.9930" RightMargin="-222.9930" TopMargin="4.3377" BottomMargin="-22.3377" Scale9Enable="True" LeftEage="9" RightEage="9" TopEage="5" BottomEage="5" Scale9OriginX="9" Scale9OriginY="5" Scale9Width="12" Scale9Height="8" ctype="ImageViewObjectData">
                <Size X="30.0000" Y="18.0000" />
                <AnchorPoint ScaleY="0.5000" />
                <Position X="192.9930" Y="-13.3377" />
                <Scale ScaleX="1.0000" ScaleY="1.0000" />
                <CColor A="255" R="255" G="255" B="255" />
                <PrePosition />
                <PreSize X="0.0000" Y="0.0000" />
                <FileData Type="Normal" Path="Common/newUI/jdt_bottom02_top.png" Plist="" />
              </AbstractNodeData>
              <AbstractNodeData Name="taofa" ActionTag="-2081207527" Tag="953" IconVisible="False" LeftMargin="199.6109" RightMargin="-282.6109" TopMargin="-24.0364" BottomMargin="-5.9636" FontSize="20" LabelText="讨伐次数" ShadowOffsetX="0.5000" ShadowOffsetY="0.5000" ctype="TextObjectData">
                <Size X="83.0000" Y="30.0000" />
                <AnchorPoint ScaleX="0.5000" ScaleY="0.5000" />
                <Position X="241.1109" Y="9.0364" />
                <Scale ScaleX="1.0000" ScaleY="1.0000" />
                <CColor A="255" R="255" G="255" B="255" />
                <PrePosition />
                <PreSize X="0.0000" Y="0.0000" />
                <FontResource Type="Normal" Path="fonts/cuyabra.ttf" Plist="" />
                <OutlineColor A="255" R="255" G="0" B="0" />
                <ShadowColor A="255" R="255" G="255" B="255" />
              </AbstractNodeData>
              <AbstractNodeData Name="tf_num" ActionTag="-2092995204" Tag="954" IconVisible="False" LeftMargin="195.6107" RightMargin="-286.6107" TopMargin="-0.0359" BottomMargin="-29.9641" FontSize="20" LabelText="99999999" ShadowOffsetX="0.5000" ShadowOffsetY="0.5000" ctype="TextObjectData">
                <Size X="91.0000" Y="30.0000" />
                <AnchorPoint ScaleX="0.5000" ScaleY="0.5000" />
                <Position X="241.1107" Y="-14.9641" />
                <Scale ScaleX="1.0000" ScaleY="1.0000" />
                <CColor A="255" R="255" G="255" B="255" />
                <PrePosition />
                <PreSize X="0.0000" Y="0.0000" />
                <FontResource Type="Normal" Path="fonts/cuyabra.ttf" Plist="" />
                <OutlineColor A="255" R="255" G="0" B="0" />
                <ShadowColor A="255" R="255" G="255" B="255" />
              </AbstractNodeData>
              <AbstractNodeData Name="strength_add" ActionTag="755867955" Tag="955" IconVisible="False" LeftMargin="297.9391" RightMargin="-335.9391" TopMargin="-25.2511" BottomMargin="-12.7489" TouchEnable="True" FontSize="14" Scale9Enable="True" LeftEage="15" RightEage="15" TopEage="11" BottomEage="11" Scale9OriginX="15" Scale9OriginY="11" Scale9Width="8" Scale9Height="16" ShadowOffsetX="2.0000" ShadowOffsetY="-2.0000" ctype="ButtonObjectData">
                <Size X="38.0000" Y="38.0000" />
                <AnchorPoint ScaleX="0.5000" ScaleY="0.5000" />
                <Position X="316.9391" Y="6.2511" />
                <Scale ScaleX="1.0000" ScaleY="1.0000" />
                <CColor A="255" R="255" G="255" B="255" />
                <PrePosition />
                <PreSize X="0.0000" Y="0.0000" />
                <TextColor A="255" R="65" G="65" B="70" />
                <DisabledFileData Type="Default" Path="Default/Button_Disable.png" Plist="" />
                <PressedFileData Type="Normal" Path="Common/newUI/button_jia_light.png" Plist="" />
                <NormalFileData Type="Normal" Path="Common/newUI/button_jia.png" Plist="" />
                <OutlineColor A="255" R="255" G="0" B="0" />
                <ShadowColor A="255" R="110" G="110" B="110" />
              </AbstractNodeData>
            </Children>
            <AnchorPoint />
            <Position X="670.5991" Y="730.0000" />
            <Scale ScaleX="1.0000" ScaleY="1.0000" />
            <CColor A="255" R="255" G="255" B="255" />
            <PrePosition X="0.5903" Y="0.9505" />
            <PreSize X="0.0000" Y="0.0000" />
          </AbstractNodeData>
        </Children>
      </ObjectData>
    </Content>
  </Content>
</GameFile>