<GameFile>
  <PropertyGroup Name="BtnActivateNode" Type="Node" ID="c0a3954b-9716-41c3-8924-11e5104305bc" Version="3.10.0.0" />
  <Content ctype="GameProjectContent">
    <Content>
      <Animation Duration="90" Speed="1.0000">
        <Timeline ActionTag="499057943" Property="Position">
          <PointFrame FrameIndex="0" X="0.0000" Y="-53.0000">
            <EasingData Type="0" />
          </PointFrame>
          <PointFrame FrameIndex="45" X="0.0000" Y="-38.0000">
            <EasingData Type="0" />
          </PointFrame>
          <PointFrame FrameIndex="90" X="0.0000" Y="-53.0000">
            <EasingData Type="0" />
          </PointFrame>
        </Timeline>
        <Timeline ActionTag="499057943" Property="Scale">
          <ScaleFrame FrameIndex="0" X="0.7000" Y="0.7000">
            <EasingData Type="0" />
          </ScaleFrame>
          <ScaleFrame FrameIndex="45" X="0.7000" Y="0.7000">
            <EasingData Type="0" />
          </ScaleFrame>
          <ScaleFrame FrameIndex="90" X="0.7000" Y="0.7000">
            <EasingData Type="0" />
          </ScaleFrame>
        </Timeline>
        <Timeline ActionTag="499057943" Property="RotationSkew">
          <ScaleFrame FrameIndex="0" X="180.0000" Y="180.0000">
            <EasingData Type="0" />
          </ScaleFrame>
          <ScaleFrame FrameIndex="45" X="180.0000" Y="180.0000">
            <EasingData Type="0" />
          </ScaleFrame>
          <ScaleFrame FrameIndex="90" X="180.0000" Y="180.0000">
            <EasingData Type="0" />
          </ScaleFrame>
        </Timeline>
      </Animation>
      <AnimationList>
        <AnimationInfo Name="1" StartIndex="0" EndIndex="90">
          <RenderColor A="255" R="135" G="206" B="250" />
        </AnimationInfo>
      </AnimationList>
      <ObjectData Name="Node" Tag="394" ctype="GameNodeObjectData">
        <Size X="0.0000" Y="0.0000" />
        <Children>
          <AbstractNodeData Name="btn" ActionTag="67797556" Tag="395" IconVisible="False" LeftMargin="-44.5000" RightMargin="-44.5000" TopMargin="-44.5000" BottomMargin="-44.5000" TouchEnable="True" FontSize="14" Scale9Enable="True" LeftEage="15" RightEage="15" TopEage="11" BottomEage="11" Scale9OriginX="15" Scale9OriginY="11" Scale9Width="59" Scale9Height="67" ShadowOffsetX="2.0000" ShadowOffsetY="-2.0000" ctype="ButtonObjectData">
            <Size X="89.0000" Y="89.0000" />
            <Children>
              <AbstractNodeData Name="text" ActionTag="1352460700" Tag="396" IconVisible="False" LeftMargin="23.1839" RightMargin="22.8161" TopMargin="34.3550" BottomMargin="24.6450" FontSize="20" LabelText="激活" ShadowOffsetX="0.5000" ShadowOffsetY="0.5000" ctype="TextObjectData">
                <Size X="43.0000" Y="30.0000" />
                <AnchorPoint ScaleX="0.5000" ScaleY="0.5000" />
                <Position X="44.6839" Y="39.6450" />
                <Scale ScaleX="1.0000" ScaleY="1.0000" />
                <CColor A="255" R="255" G="255" B="255" />
                <PrePosition X="0.5021" Y="0.4454" />
                <PreSize X="0.4831" Y="0.3371" />
                <FontResource Type="Normal" Path="fonts/cuyabra.ttf" Plist="" />
                <OutlineColor A="255" R="255" G="0" B="0" />
                <ShadowColor A="255" R="255" G="255" B="255" />
              </AbstractNodeData>
            </Children>
            <AnchorPoint ScaleX="0.5000" ScaleY="0.5000" />
            <Position />
            <Scale ScaleX="1.0000" ScaleY="1.0000" />
            <CColor A="255" R="255" G="255" B="255" />
            <PrePosition />
            <PreSize X="0.0000" Y="0.0000" />
            <TextColor A="255" R="65" G="65" B="70" />
            <DisabledFileData Type="Default" Path="Default/Button_Disable.png" Plist="" />
            <PressedFileData Type="Normal" Path="Common/ui2/guide_jihuo_wl.png" Plist="" />
            <NormalFileData Type="Normal" Path="Common/ui2/guide_jihuo_wl.png" Plist="" />
            <OutlineColor A="255" R="255" G="0" B="0" />
            <ShadowColor A="255" R="110" G="110" B="110" />
          </AbstractNodeData>
          <AbstractNodeData Name="guide_arrow_1" ActionTag="643023133" Tag="397" IconVisible="False" LeftMargin="64.0000" RightMargin="-76.0000" TopMargin="-6.5000" BottomMargin="-6.5000" ctype="SpriteObjectData">
            <Size X="12.0000" Y="13.0000" />
            <AnchorPoint ScaleX="0.5000" ScaleY="0.5000" />
            <Position X="70.0000" />
            <Scale ScaleX="1.0000" ScaleY="1.0000" />
            <CColor A="255" R="255" G="255" B="255" />
            <PrePosition />
            <PreSize X="0.0000" Y="0.0000" />
            <FileData Type="Normal" Path="Common/ui2/guide_arrow.png" Plist="" />
            <BlendFunc Src="1" Dst="771" />
          </AbstractNodeData>
          <AbstractNodeData Name="guide_arrow_1_0" ActionTag="-426693286" Tag="398" IconVisible="False" LeftMargin="-76.0000" RightMargin="64.0000" TopMargin="-6.5000" BottomMargin="-6.5000" FlipX="True" ctype="SpriteObjectData">
            <Size X="12.0000" Y="13.0000" />
            <AnchorPoint ScaleX="0.5000" ScaleY="0.5000" />
            <Position X="-70.0000" />
            <Scale ScaleX="1.0000" ScaleY="1.0000" />
            <CColor A="255" R="255" G="255" B="255" />
            <PrePosition />
            <PreSize X="0.0000" Y="0.0000" />
            <FileData Type="Normal" Path="Common/ui2/guide_arrow.png" Plist="" />
            <BlendFunc Src="1" Dst="771" />
          </AbstractNodeData>
          <AbstractNodeData Name="jiantou" ActionTag="499057943" VisibleForFrame="False" Tag="1825" RotationSkewX="180.0000" RotationSkewY="180.0000" IconVisible="False" LeftMargin="-29.0000" RightMargin="-29.0000" TopMargin="18.0000" BottomMargin="-88.0000" LeftEage="19" RightEage="19" TopEage="23" BottomEage="23" Scale9OriginX="19" Scale9OriginY="23" Scale9Width="20" Scale9Height="24" ctype="ImageViewObjectData">
            <Size X="58.0000" Y="70.0000" />
            <AnchorPoint ScaleX="0.5000" ScaleY="0.5000" />
            <Position Y="-53.0000" />
            <Scale ScaleX="0.7000" ScaleY="0.7000" />
            <CColor A="255" R="255" G="255" B="255" />
            <PrePosition />
            <PreSize X="0.0000" Y="0.0000" />
            <FileData Type="Normal" Path="GuideLayer/jiantou.png" Plist="" />
          </AbstractNodeData>
        </Children>
      </ObjectData>
    </Content>
  </Content>
</GameFile>