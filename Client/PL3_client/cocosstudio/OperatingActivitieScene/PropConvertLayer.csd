<GameFile>
  <PropertyGroup Name="PropConvertLayer" Type="Layer" ID="10ef8bb5-e89d-4095-913d-6f2f83de6258" Version="3.10.0.0" />
  <Content ctype="GameProjectContent">
    <Content>
      <Animation Duration="0" Speed="1.0000" />
      <ObjectData Name="Layer" Tag="826" ctype="GameLayerObjectData">
        <Size X="1136.0000" Y="768.0000" />
        <Children>
          <AbstractNodeData Name="bg_gray" ActionTag="-183075222" Alpha="177" Tag="858" IconVisible="False" PositionPercentXEnabled="True" PositionPercentYEnabled="True" LeftMargin="-332.0000" RightMargin="-332.0000" TouchEnable="True" LeftEage="7" RightEage="7" TopEage="2" BottomEage="2" Scale9OriginX="7" Scale9OriginY="2" Scale9Width="10" Scale9Height="3" ctype="ImageViewObjectData">
            <Size X="1800.0000" Y="768.0000" />
            <AnchorPoint ScaleX="0.5000" ScaleY="0.5000" />
            <Position X="568.0000" Y="384.0000" />
            <Scale ScaleX="1.0000" ScaleY="1.0000" />
            <CColor A="255" R="26" G="26" B="26" />
            <PrePosition X="0.5000" Y="0.5000" />
            <PreSize X="1.5845" Y="1.0000" />
            <FileData Type="Normal" Path="ShipsScene/ui_bar_yellow_full.png" Plist="" />
          </AbstractNodeData>
          <AbstractNodeData Name="bg" ActionTag="1079925342" Tag="859" IconVisible="False" LeftMargin="1.0000" RightMargin="1.0000" TopMargin="103.7016" BottomMargin="103.2984" ctype="SpriteObjectData">
            <Size X="1134.0000" Y="561.0000" />
            <AnchorPoint ScaleX="0.5000" ScaleY="0.5000" />
            <Position X="568.0000" Y="383.7984" />
            <Scale ScaleX="1.0000" ScaleY="1.0000" />
            <CColor A="255" R="255" G="255" B="255" />
            <PrePosition X="0.5000" Y="0.4997" />
            <PreSize X="0.9982" Y="0.7305" />
            <FileData Type="Normal" Path="Common/newUI/common_bj.png" Plist="" />
            <BlendFunc Src="1" Dst="771" />
          </AbstractNodeData>
          <AbstractNodeData Name="title" ActionTag="259009410" Tag="863" IconVisible="False" LeftMargin="504.9470" RightMargin="509.0530" TopMargin="125.8680" BottomMargin="610.1320" LeftEage="21" RightEage="21" TopEage="10" BottomEage="10" Scale9OriginX="21" Scale9OriginY="10" Scale9Width="80" Scale9Height="12" ctype="ImageViewObjectData">
            <Size X="122.0000" Y="32.0000" />
            <AnchorPoint ScaleX="0.5000" ScaleY="0.5000" />
            <Position X="565.9470" Y="626.1320" />
            <Scale ScaleX="1.0000" ScaleY="1.0000" />
            <CColor A="255" R="255" G="255" B="255" />
            <PrePosition X="0.4982" Y="0.8153" />
            <PreSize X="0.1074" Y="0.0417" />
            <FileData Type="Normal" Path="OperatingActivitieScene/ui/propconvert.png" Plist="" />
          </AbstractNodeData>
          <AbstractNodeData Name="close" ActionTag="544049724" Tag="864" IconVisible="False" LeftMargin="998.5322" RightMargin="85.4678" TopMargin="118.1127" BottomMargin="597.8873" TouchEnable="True" FontSize="14" LeftEage="15" RightEage="15" TopEage="11" BottomEage="11" Scale9OriginX="15" Scale9OriginY="11" Scale9Width="22" Scale9Height="30" ShadowOffsetX="2.0000" ShadowOffsetY="-2.0000" ctype="ButtonObjectData">
            <Size X="52.0000" Y="52.0000" />
            <AnchorPoint ScaleX="0.5000" ScaleY="0.5000" />
            <Position X="1024.5322" Y="623.8873" />
            <Scale ScaleX="1.0000" ScaleY="1.0000" />
            <CColor A="255" R="255" G="255" B="255" />
            <PrePosition X="0.9019" Y="0.8124" />
            <PreSize X="0.0458" Y="0.0677" />
            <TextColor A="255" R="65" G="65" B="70" />
            <DisabledFileData Type="Default" Path="Default/Button_Disable.png" Plist="" />
            <PressedFileData Type="Normal" Path="Common/newUI/button_close_light.png" Plist="" />
            <NormalFileData Type="Normal" Path="Common/newUI/button_close.png" Plist="" />
            <OutlineColor A="255" R="255" G="0" B="0" />
            <ShadowColor A="255" R="110" G="110" B="110" />
          </AbstractNodeData>
          <AbstractNodeData Name="list" ActionTag="1085220803" Tag="865" IconVisible="False" LeftMargin="108.5668" RightMargin="107.4332" TopMargin="180.4752" BottomMargin="167.5248" TouchEnable="True" ClipAble="True" BackColorAlpha="0" ColorAngle="90.0000" Scale9Width="1" Scale9Height="1" IsBounceEnabled="True" ScrollDirectionType="Vertical" ctype="ScrollViewObjectData">
            <Size X="920.0000" Y="420.0000" />
            <AnchorPoint ScaleY="1.0000" />
            <Position X="108.5668" Y="587.5248" />
            <Scale ScaleX="1.0000" ScaleY="1.0000" />
            <CColor A="255" R="255" G="255" B="255" />
            <PrePosition X="0.0956" Y="0.7650" />
            <PreSize X="0.8099" Y="0.5469" />
            <SingleColor A="255" R="255" G="150" B="100" />
            <FirstColor A="255" R="255" G="150" B="100" />
            <EndColor A="255" R="255" G="255" B="255" />
            <ColorVector ScaleY="1.0000" />
            <InnerNodeSize Width="920" Height="420" />
          </AbstractNodeData>
          <AbstractNodeData Name="Text_1" ActionTag="-1968787151" Tag="1823" IconVisible="False" LeftMargin="111.2326" RightMargin="902.7675" TopMargin="608.6400" BottomMargin="132.3600" FontSize="18" LabelText="活动剩余时间：" ShadowOffsetX="2.0000" ShadowOffsetY="-2.0000" ctype="TextObjectData">
            <Size X="122.0000" Y="27.0000" />
            <AnchorPoint ScaleX="0.5000" ScaleY="0.5000" />
            <Position X="172.2326" Y="145.8600" />
            <Scale ScaleX="1.0000" ScaleY="1.0000" />
            <CColor A="255" R="255" G="255" B="255" />
            <PrePosition X="0.1516" Y="0.1899" />
            <PreSize X="0.1074" Y="0.0352" />
            <FontResource Type="Normal" Path="fonts/cuyabra.ttf" Plist="" />
            <OutlineColor A="255" R="255" G="0" B="0" />
            <ShadowColor A="255" R="110" G="110" B="110" />
          </AbstractNodeData>
          <AbstractNodeData Name="time" ActionTag="-2093295655" Tag="1824" IconVisible="False" LeftMargin="237.5239" RightMargin="815.4761" TopMargin="608.6400" BottomMargin="132.3600" FontSize="18" LabelText="156:20:38" ShadowOffsetX="2.0000" ShadowOffsetY="-2.0000" ctype="TextObjectData">
            <Size X="83.0000" Y="27.0000" />
            <AnchorPoint ScaleX="0.5000" ScaleY="0.5000" />
            <Position X="279.0239" Y="145.8600" />
            <Scale ScaleX="1.0000" ScaleY="1.0000" />
            <CColor A="255" R="255" G="0" B="0" />
            <PrePosition X="0.2456" Y="0.1899" />
            <PreSize X="0.0731" Y="0.0352" />
            <FontResource Type="Normal" Path="fonts/cuyabra.ttf" Plist="" />
            <OutlineColor A="255" R="255" G="0" B="0" />
            <ShadowColor A="255" R="110" G="110" B="110" />
          </AbstractNodeData>
        </Children>
      </ObjectData>
    </Content>
  </Content>
</GameFile>