-- Living Commish frame-sequence renderer.
-- Uses the approved 512x512 transparent PNG assets already embedded in this file.

type CommishPlayback = {
  context: Context?,
  sampler: ImageSampler?,
  prefix: string,
  frameIndex: number,
  frameCount: number,
  elapsed: number,
  looping: boolean,
}

local FRAME_DURATION = 1 / 24

local function beginAction(
  self: CommishPlayback,
  prefix: string,
  frameCount: number,
  looping: boolean
)
  self.prefix = prefix
  self.frameIndex = 0
  self.frameCount = frameCount
  self.elapsed = 0
  self.looping = looping
end

local function beginIdle(self: CommishPlayback)
  beginAction(self, "01_idle_", 90, true)
end

local function init(self: CommishPlayback, context: Context): boolean
  self.context = context
  self.sampler = ImageSampler("clamp", "clamp", "bilinear")
  beginIdle(self)

  local viewModel = context:viewModel()
  if not viewModel then
    viewModel = context:rootViewModel()
  end

  if viewModel then
    local pointRight = viewModel:getTrigger("pointRight")
    if pointRight then
      pointRight:addListener(function()
        beginAction(self, "02_point-right_", 90, false)
      end)
    end

    local sadShrug = viewModel:getTrigger("sadShrug")
    if sadShrug then
      sadShrug:addListener(function()
        beginAction(self, "03_sad-shrug_", 90, false)
      end)
    end

    local wave = viewModel:getTrigger("wave")
    if wave then
      wave:addListener(function()
        beginAction(self, "04_wave_", 60, false)
      end)
    end

    local foamFinger = viewModel:getTrigger("foamFinger")
    if foamFinger then
      foamFinger:addListener(function()
        beginAction(self, "05_foam-finger_", 90, false)
      end)
    end
  end

  return true
end

local function advance(self: CommishPlayback, seconds: number): boolean
  self.elapsed += seconds

  while self.elapsed >= FRAME_DURATION do
    self.elapsed -= FRAME_DURATION
    self.frameIndex += 1

    if self.frameIndex >= self.frameCount then
      if self.looping then
        self.frameIndex = 0
      else
        beginIdle(self)
      end
    end
  end

  return true
end

local function draw(self: CommishPlayback, renderer: Renderer)
  if not self.context or not self.sampler then
    return
  end

  local assetName = string.format("%s%03d", self.prefix, self.frameIndex)
  local image = self.context:image(assetName)
  if image then
    renderer:drawImage(image, self.sampler, "srcOver", 1)
  end
end

return function(): Node<CommishPlayback>
  return {
    context = nil,
    sampler = nil,
    prefix = "01_idle_",
    frameIndex = 0,
    frameCount = 90,
    elapsed = 0,
    looping = true,
    init = init,
    advance = advance,
    draw = draw,
  }
end
