<GameFile>
  <PropertyGroup Name="AttrLabel" Type="Node" ID="b4d115aa-52b0-42d4-b24f-09e47d972a9b" Version="3.10.0.0" />
  <Content ctype="GameProjectContent">
    <Content>
      <Animation Duration="145" Speed="1.0000" ActivedAnimationName="sub">
        <Timeline ActionTag="731287284" Property="Position">
          <PointFrame FrameIndex="0" X="0.0000" Y="60.0000">
            <EasingData Type="0" />
          </PointFrame>
          <PointFrame FrameIndex="70" X="0.0000" Y="90.0000">
            <EasingData Type="0" />
          </PointFrame>
        </Timeline>
        <Timeline ActionTag="731287284" Property="Scale">
          <ScaleFrame FrameIndex="0" X="1.0000" Y="1.0000">
            <EasingData Type="0" />
          </ScaleFrame>
          <ScaleFrame FrameIndex="70" X="1.0000" Y="1.0000">
            <EasingData Type="0" />
          </ScaleFrame>
        </Timeline>
        <Timeline ActionTag="731287284" Property="RotationSkew">
          <ScaleFrame FrameIndex="0" X="0.0000" Y="0.0000">
            <EasingData Type="0" />
          </ScaleFrame>
          <ScaleFrame FrameIndex="70" X="0.0000" Y="0.0000">
            <EasingData Type="0" />
          </ScaleFrame>
        </Timeline>
        <Timeline ActionTag="731287284" Property="VisibleForFrame">
          <BoolFrame FrameIndex="0" Tween="False" Value="True" />
          <BoolFrame FrameIndex="75" Tween="False" Value="False" />
        </Timeline>
        <Timeline ActionTag="1185387695" Property="Position">
          <PointFrame FrameIndex="75" X="0.0000" Y="60.0000">
            <EasingData Type="0" />
          </PointFrame>
          <PointFrame FrameIndex="145" X="0.0000" Y="90.0000">
            <EasingData Type="0" />
          </PointFrame>
        </Timeline>
        <Timeline ActionTag="1185387695" Property="Scale">
          <ScaleFrame FrameIndex="75" X="1.0000" Y="1.0000">
            <EasingData Type="0" />
          </ScaleFrame>
          <ScaleFrame FrameIndex="145" X="1.0000" Y="1.0000">
            <EasingData Type="0" />
          </ScaleFrame>
        </Timeline>
        <Timeline ActionTag="1185387695" Property="RotationSkew">
          <ScaleFrame FrameIndex="75" X="0.0000" Y="0.0000">
            <EasingData Type="0" />
          </ScaleFrame>
          <ScaleFrame FrameIndex="145" X="0.0000" Y="0.0000">
            <EasingData Type="0" />
          </ScaleFrame>
        </Timeline>
        <Timeline ActionTag="1185387695" Property="VisibleForFrame">
          <BoolFrame FrameIndex="0" Tween="False" Value="False" />
          <BoolFrame FrameIndex="75" Tween="False" Value="True" />
        </Timeline>
      </Animation>
      <AnimationList>
        <AnimationInfo Name="add" StartIndex="0" EndIndex="70">
          <RenderColor A="255" R="0" G="0" B="205" />
        </AnimationInfo>
        <AnimationInfo Name="sub" StartIndex="75" EndIndex="145">
          <RenderColor A="255" R="255" G="250" B="205" />
        </AnimationInfo>
      </AnimationList>
      <ObjectData Name="Node" Tag="66" ctype="GameNodeObjectData">
        <Size X="0.0000" Y="0.0000" />
        <Children>
          <AbstractNodeData Name="add" ActionTag="731287284" VisibleForFrame="False" Tag="68" IconVisible="False" LeftMargin="-53.5000" RightMargin="-53.5000" TopMargin="-105.0000" BottomMargin="75.0000" FontSize="20" LabelText="Attak+10%" ShadowOffsetX="0.5000" ShadowOffsetY="0.5000" ctype="TextObjectData">
            <Size X="107.0000" Y="30.0000" />
            <AnchorPoint ScaleX="0.5000" ScaleY="0.5000" />
            <Position Y="90.0000" />
            <Scale ScaleX="1.0000" ScaleY="1.0000" />
            <CColor A="255" R="144" G="238" B="144" />
            <PrePosition />
            <PreSize X="0.0000" Y="0.0000" />
            <FontResource Type="Normal" Path="fonts/cuyabra.ttf" Plist="" />
            <OutlineColor A="255" R="255" G="0" B="0" />
            <ShadowColor A="255" R="144" G="238" B="144" />
          </AbstractNodeData>
          <AbstractNodeData Name="sub" ActionTag="1185387695" Tag="70" IconVisible="False" LeftMargin="-53.5000" RightMargin="-53.5000" TopMargin="-105.0000" BottomMargin="75.0000" FontSize="20" LabelText="Attak+10%" ShadowOffsetX="0.5000" ShadowOffsetY="0.5000" ctype="TextObjectData">
            <Size X="107.0000" Y="30.0000" />
            <AnchorPoint ScaleX="0.5000" ScaleY="0.5000" />
            <Position Y="90.0000" />
            <Scale ScaleX="1.0000" ScaleY="1.0000" />
            <CColor A="255" R="255" G="0" B="0" />
            <PrePosition />
            <PreSize X="0.0000" Y="0.0000" />
            <FontResource Type="Normal" Path="fonts/cuyabra.ttf" Plist="" />
            <OutlineColor A="255" R="255" G="0" B="0" />
            <ShadowColor A="255" R="255" G="0" B="0" />
          </AbstractNodeData>
        </Children>
      </ObjectData>
    </Content>
  </Content>
</GameFile>