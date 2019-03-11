<GameFile>
  <PropertyGroup Name="fangyuta_2" Type="Node" ID="888afc04-c579-4b41-b076-96185ac000fc" Version="3.10.0.0" />
  <Content ctype="GameProjectContent">
    <Content>
      <Animation Duration="26" Speed="1.0000" ActivedAnimationName="2">
        <Timeline ActionTag="1545582274" Property="FileData">
          <TextureFrame FrameIndex="0" Tween="False">
            <TextureFile Type="Normal" Path="PlanetScene/sfx/fangyuta/gongji/1_00000.png" Plist="" />
          </TextureFrame>
          <TextureFrame FrameIndex="5" Tween="False">
            <TextureFile Type="Normal" Path="PlanetScene/sfx/fangyuta/gongji/1_00001.png" Plist="" />
          </TextureFrame>
          <TextureFrame FrameIndex="10" Tween="False">
            <TextureFile Type="Normal" Path="PlanetScene/sfx/fangyuta/gongji/1_00002.png" Plist="" />
          </TextureFrame>
          <TextureFrame FrameIndex="15" Tween="False">
            <TextureFile Type="Normal" Path="PlanetScene/sfx/fangyuta/gongji/1_00003.png" Plist="" />
          </TextureFrame>
          <TextureFrame FrameIndex="20" Tween="False">
            <TextureFile Type="Normal" Path="PlanetScene/sfx/fangyuta/gongji/1_00004.png" Plist="" />
          </TextureFrame>
          <TextureFrame FrameIndex="25" Tween="False">
            <TextureFile Type="Normal" Path="PlanetScene/sfx/fangyuta/gongji/1_00005.png" Plist="" />
          </TextureFrame>
        </Timeline>
        <Timeline ActionTag="1545582274" Property="Alpha">
          <IntFrame FrameIndex="0" Value="255">
            <EasingData Type="0" />
          </IntFrame>
          <IntFrame FrameIndex="25" Value="255">
            <EasingData Type="0" />
          </IntFrame>
          <IntFrame FrameIndex="26" Value="0">
            <EasingData Type="0" />
          </IntFrame>
        </Timeline>
        <Timeline ActionTag="1545582274" Property="FrameEvent">
          <EventFrame FrameIndex="25" Tween="False" Value="attackover" />
          <EventFrame FrameIndex="26" Tween="False" Value="" />
        </Timeline>
      </Animation>
      <AnimationList>
        <AnimationInfo Name="2" StartIndex="0" EndIndex="26">
          <RenderColor A="255" R="0" G="139" B="139" />
        </AnimationInfo>
      </AnimationList>
      <ObjectData Name="Node" Tag="79" ctype="GameNodeObjectData">
        <Size X="0.0000" Y="0.0000" />
        <Children>
          <AbstractNodeData Name="Sprite_2" ActionTag="1545582274" Tag="81" FrameEvent="attackover" IconVisible="False" LeftMargin="-130.7274" RightMargin="-752.2726" TopMargin="-131.4747" BottomMargin="-118.5253" ctype="SpriteObjectData">
            <Size X="883.0000" Y="250.0000" />
            <AnchorPoint ScaleY="0.5000" />
            <Position X="-130.7274" Y="6.4747" />
            <Scale ScaleX="1.0000" ScaleY="1.0000" />
            <CColor A="255" R="255" G="255" B="255" />
            <PrePosition />
            <PreSize X="0.0000" Y="0.0000" />
            <FileData Type="Normal" Path="PlanetScene/sfx/fangyuta/gongji/1_00005.png" Plist="" />
            <BlendFunc Src="1" Dst="771" />
          </AbstractNodeData>
        </Children>
      </ObjectData>
    </Content>
  </Content>
</GameFile>