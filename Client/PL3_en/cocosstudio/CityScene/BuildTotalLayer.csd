<GameFile>
  <PropertyGroup Name="BuildTotalLayer" Type="Layer" ID="db0e21c2-a673-415e-a564-0f0b83ea13f3" Version="3.10.0.0" />
  <Content ctype="GameProjectContent">
    <Content>
      <Animation Duration="40" Speed="1.0000" ActivedAnimationName="animation0">
        <Timeline ActionTag="-652855895" Property="Position">
          <PointFrame FrameIndex="0" X="413.0756" Y="291.7669">
            <EasingData Type="0" />
          </PointFrame>
        </Timeline>
        <Timeline ActionTag="1745539230" Property="Position">
          <PointFrame FrameIndex="0" X="-389.0000" Y="345.0000">
            <EasingData Type="0" />
          </PointFrame>
          <PointFrame FrameIndex="40" X="0.0000" Y="345.0000">
            <EasingData Type="0" />
          </PointFrame>
        </Timeline>
        <Timeline ActionTag="1745539230" Property="Alpha">
          <IntFrame FrameIndex="0" Value="0">
            <EasingData Type="0" />
          </IntFrame>
          <IntFrame FrameIndex="40" Value="255">
            <EasingData Type="0" />
          </IntFrame>
        </Timeline>
      </Animation>
      <AnimationList>
        <AnimationInfo Name="animation0" StartIndex="0" EndIndex="40">
          <RenderColor A="255" R="128" G="0" B="128" />
        </AnimationInfo>
      </AnimationList>
      <ObjectData Name="Layer" Tag="2003" ctype="GameLayerObjectData">
        <Size X="1136.0000" Y="768.0000" />
        <Children>
          <AbstractNodeData Name="touch" ActionTag="1604839572" Tag="264" IconVisible="False" LeftMargin="-482.0002" RightMargin="-481.9998" TopMargin="-0.7846" BottomMargin="0.7846" TouchEnable="True" ClipAble="False" BackColorAlpha="102" ColorAngle="90.0000" Scale9Width="1" Scale9Height="1" ctype="PanelObjectData">
            <Size X="2100.0000" Y="768.0000" />
            <AnchorPoint ScaleX="0.5000" ScaleY="0.5000" />
            <Position X="567.9998" Y="384.7846" />
            <Scale ScaleX="1.0000" ScaleY="1.0000" />
            <CColor A="255" R="255" G="255" B="255" />
            <PrePosition X="0.5000" Y="0.5010" />
            <PreSize X="1.8486" Y="1.0000" />
            <SingleColor A="255" R="150" G="200" B="255" />
            <FirstColor A="255" R="150" G="200" B="255" />
            <EndColor A="255" R="255" G="255" B="255" />
            <ColorVector ScaleY="1.0000" />
          </AbstractNodeData>
          <AbstractNodeData Name="bg" ActionTag="1745539230" UserData="left" Tag="2004" IconVisible="False" RightMargin="748.0000" TopMargin="188.5000" BottomMargin="110.5000" Scale9Enable="True" LeftEage="72" RightEage="67" TopEage="95" BottomEage="93" Scale9OriginX="72" Scale9OriginY="95" Scale9Width="24" Scale9Height="28" ctype="ImageViewObjectData">
            <Size X="388.0000" Y="469.0000" />
            <Children>
              <AbstractNodeData Name="close" ActionTag="-652855895" Tag="2006" IconVisible="False" LeftMargin="387.5756" RightMargin="-50.5756" TopMargin="116.2331" BottomMargin="230.7669" TouchEnable="True" FontSize="14" Scale9Enable="True" LeftEage="15" RightEage="15" TopEage="11" BottomEage="11" Scale9OriginX="15" Scale9OriginY="11" Scale9Width="21" Scale9Height="100" ShadowOffsetX="2.0000" ShadowOffsetY="-2.0000" ctype="ButtonObjectData">
                <Size X="51.0000" Y="122.0000" />
                <Children>
                  <AbstractNodeData Name="text" ActionTag="-320357934" VisibleForFrame="False" Tag="2007" IconVisible="False" LeftMargin="7.7608" RightMargin="19.2392" TopMargin="-26.4883" BottomMargin="91.4883" IsCustomSize="True" FontSize="22" LabelText="总览" ShadowOffsetX="0.5000" ShadowOffsetY="0.5000" ctype="TextObjectData">
                    <Size X="24.0000" Y="57.0000" />
                    <AnchorPoint ScaleX="0.5000" ScaleY="0.5000" />
                    <Position X="19.7608" Y="119.9883" />
                    <Scale ScaleX="1.0000" ScaleY="1.0000" />
                    <CColor A="255" R="255" G="255" B="255" />
                    <PrePosition X="0.3875" Y="0.9835" />
                    <PreSize X="0.4706" Y="0.4672" />
                    <FontResource Type="Normal" Path="fonts/cuyabra.ttf" Plist="" />
                    <OutlineColor A="255" R="255" G="255" B="255" />
                    <ShadowColor A="255" R="255" G="255" B="255" />
                  </AbstractNodeData>
                </Children>
                <AnchorPoint ScaleX="0.5000" ScaleY="0.5000" />
                <Position X="413.0756" Y="291.7669" />
                <Scale ScaleX="1.0000" ScaleY="1.0000" />
                <CColor A="255" R="255" G="255" B="255" />
                <PrePosition X="1.0646" Y="0.6221" />
                <PreSize X="0.1314" Y="0.2601" />
                <TextColor A="255" R="65" G="65" B="70" />
                <DisabledFileData Type="Default" Path="Default/Button_Disable.png" Plist="" />
                <NormalFileData Type="Normal" Path="CityScene/ui3/btn_totaldown.png" Plist="" />
                <OutlineColor A="255" R="255" G="0" B="0" />
                <ShadowColor A="255" R="110" G="110" B="110" />
              </AbstractNodeData>
              <AbstractNodeData Name="list" ActionTag="-428761275" Tag="2008" IconVisible="False" LeftMargin="1.1551" RightMargin="16.8449" TopMargin="17.7799" BottomMargin="11.2201" TouchEnable="True" ClipAble="True" BackColorAlpha="102" ColorAngle="90.0000" Scale9Width="1" Scale9Height="1" IsBounceEnabled="True" ScrollDirectionType="Vertical" ctype="ScrollViewObjectData">
                <Size X="370.0000" Y="440.0000" />
                <AnchorPoint ScaleX="1.0000" />
                <Position X="371.1551" Y="11.2201" />
                <Scale ScaleX="1.0000" ScaleY="1.0000" />
                <CColor A="255" R="255" G="255" B="255" />
                <PrePosition X="0.9566" Y="0.0239" />
                <PreSize X="0.9536" Y="0.9382" />
                <SingleColor A="255" R="255" G="150" B="100" />
                <FirstColor A="255" R="255" G="150" B="100" />
                <EndColor A="255" R="255" G="255" B="255" />
                <ColorVector ScaleY="1.0000" />
                <InnerNodeSize Width="380" Height="480" />
              </AbstractNodeData>
            </Children>
            <AnchorPoint ScaleY="0.5000" />
            <Position Y="345.0000" />
            <Scale ScaleX="1.0000" ScaleY="1.0000" />
            <CColor A="255" R="255" G="255" B="255" />
            <PrePosition Y="0.4492" />
            <PreSize X="0.3415" Y="0.6107" />
            <FileData Type="Normal" Path="CityScene/ui3/image_totaldown.png" Plist="" />
          </AbstractNodeData>
        </Children>
      </ObjectData>
    </Content>
  </Content>
</GameFile>