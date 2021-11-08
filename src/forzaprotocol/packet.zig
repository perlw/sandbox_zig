pub const Packet = packed struct {
    Running: i32, // 0 in menus, 1 when not.
    Timestamp: u32,
    EngineMaxRpm: f32,
    EngineIdleRpm: f32,
    CurrentEngineRpm: f32,
    AccelerationX: f32,
    AccelerationY: f32,
    AccelerationZ: f32,
    VelocityX: f32,
    VelocityY: f32,
    VelocityZ: f32,
    AngularVelocityX: f32,
    AngularVelocityY: f32,
    AngularVelocityZ: f32,
    Yaw: f32,
    Pitch: f32,
    Roll: f32,
    NormalizedSuspensionFrontLeft: f32, // 0.0 - relaxed, 1.0 - compressed.
    NormalizedSuspensionFrontRight: f32,
    NormalizedSuspensionRearLeft: f32,
    NormalizedSuspensionRearRight: f32,
    TireSlipRatioFrontLeft: f32, // 0.0 - max grip, 1.0+ - no grip.
    TireSlipRatioFrontRight: f32,
    TireSlipRatioRearLeft: f32,
    TireSlipRatioRearRight: f32,
    WheelRotationSpeedFrontLeft: f32, // Radians p/sec.
    WheelRotationSpeedFrontRight: f32,
    WheelRotationSpeedRearLeft: f32,
    WheelRotationSpeedRearRight: f32,
    WheelOnRumbleStripFrontLeft: i32, // 0 when not on rumble strip, 1 when on.
    WheelOnRumbleStripFrontRight: i32,
    WheelOnRumbleStripRearLeft: i32,
    WheelOnRumbleStripRearRight: i32,
    WheelInPuddleDepthFrontLeft: f32, // 0.0 - no puddle, 1.0 - deep puddle.
    WheelInPuddleDepthFrontRight: f32,
    WheelInPuddleDepthRearLeft: f32,
    WheelInPuddleDepthRearRight: f32,
    SurfaceRumbleFrontLeft: f32,
    SurfaceRumbleFrontRight: f32,
    SurfaceRumbleRearLeft: f32,
    SurfaceRumbleRearRight: f32,
    TireSlipAngleFrontLeft: f32, // 0.0 - max grip, 1.0+ - no grip.
    TireSlipAngleFrontRight: f32,
    TireSlipAngleRearLeft: f32,
    TireSlipAngleRearRight: f32,
    TireCombinedSlipFrontLeft: f32, // 0.0 - max grip, 1.0+ - no grip.
    TireCombinedSlipFrontRight: f32,
    TireCombinedSlipRearLeft: f32,
    TireCombinedSlipRearRight: f32,
    SuspensionTravelMetersFrontLeft: f32,
    SuspensionTravelMetersFrontRight: f32,
    SuspensionTravelMetersRearLeft: f32,
    SuspensionTravelMetersRearRight: f32,
    CarID: i32,
    CarClass: i32, // 0: D, 1: C, 2: B, 3: A, 4: S1, 5: S2, 6: R, 7: X.
    CarPerformanceIndex: i32,
    Drivetrain: i32, // 0: FWD, 1: RWD, 2: AWD.
    NumCylinders: i32,
    Unknown: [12]u8,
    PositionX: f32, // Meters.
    PositionY: f32, // Meters.
    PositionZ: f32, // Meters.
    Speed: f32, // Meters per second.
    Power: f32, // Watts.
    Torque: f32, // Newtonmeter.
    TireTempFrontLeft: f32,
    TireTempFrontRight: f32,
    TireTempRearLeft: f32,
    TireTempRearRight: f32,
    Boost: f32,
    Fuel: f32,
    DistanceTraveled: f32,
    BestLap: f32,
    LastLap: f32,
    CurrentLap: f32,
    CurrentRaceTime: f32,
    LapNumber: u16,
    RacePosition: u8,
    Accel: u8,
    Brake: u8,
    Clutch: u8,
    Handbrake: u8,
    Gear: u8,
    Steer: i8,
    NormalizedDrivingLine: i8,
    NormalizedAIBrakeDifference: i8,
};
