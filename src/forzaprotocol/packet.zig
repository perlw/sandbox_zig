pub const Packet = packed struct {
    running: i32, // 0 in menus, 1 when not.
    timestamp: u32,
    engine_max_rpm: f32,
    engine_idle_rpm: f32,
    current_engine_rpm: f32,
    acceleration_x: f32,
    acceleration_y: f32,
    acceleration_z: f32,
    velocity_x: f32,
    velocity_y: f32,
    velocity_z: f32,
    angular_velocity_x: f32,
    angular_velocity_y: f32,
    angular_velocity_z: f32,
    yaw: f32,
    pitch: f32,
    roll: f32,
    normalized_suspension_front_left: f32, // 0.0 - relaxed, 1.0 - compressed.
    normalized_suspension_front_right: f32,
    normalized_suspension_rear_left: f32,
    normalized_suspension_rear_right: f32,
    tire_slip_ratio_front_left: f32, // 0.0 - max grip, 1.0+ - no grip.
    tire_slip_ratio_front_right: f32,
    tire_slip_ratio_rear_left: f32,
    tire_slip_ratio_rear_right: f32,
    wheel_rotation_speed_front_left: f32, // radians p/sec.
    wheel_rotation_speed_front_right: f32,
    wheel_rotation_speed_rear_left: f32,
    wheel_rotation_speed_rear_right: f32,
    wheel_on_rumble_strip_front_left: i32, // 0 when not on rumble strip, 1 when on.
    wheel_on_rumble_strip_front_right: i32,
    wheel_on_rumble_strip_rear_left: i32,
    wheel_on_rumble_strip_rear_right: i32,
    wheel_in_puddle_depth_front_left: f32, // 0.0 - no puddle, 1.0 - deep puddle.
    wheel_in_puddle_depth_front_right: f32,
    wheel_in_puddle_depth_rear_left: f32,
    wheel_in_puddle_depth_rear_right: f32,
    surface_rumble_front_left: f32,
    surface_rumble_front_right: f32,
    surface_rumble_rear_left: f32,
    surface_rumble_rear_right: f32,
    tire_slip_angle_front_left: f32, // 0.0 - max grip, 1.0+ - no grip.
    tire_slip_angle_front_right: f32,
    tire_slip_angle_rear_left: f32,
    tire_slip_angle_rear_right: f32,
    tire_combined_slip_front_left: f32, // 0.0 - max grip, 1.0+ - no grip.
    tire_combined_slip_front_right: f32,
    tire_combined_slip_rear_left: f32,
    tire_combined_slip_rear_right: f32,
    suspension_travel_meters_front_left: f32,
    suspension_travel_meters_front_right: f32,
    suspension_travel_meters_rear_left: f32,
    suspension_travel_meters_rear_right: f32,
    car_id: i32,
    car_class: i32, // 0: d, 1: c, 2: b, 3: a, 4: s1, 5: s2, 6: r, 7: x.
    car_performance_index: i32,
    drivetrain: i32, // 0: fwd, 1: rwd, 2: awd.
    num_cylinders: i32,
    unknown: [12]u8,
    position_x: f32, // meters.
    position_y: f32, // meters.
    position_z: f32, // meters.
    speed: f32, // meters per second.
    power: f32, // watts.
    torque: f32, // newtonmeter.
    tire_temp_front_left: f32,
    tire_temp_front_right: f32,
    tire_temp_rear_left: f32,
    tire_temp_rear_right: f32,
    boost: f32,
    fuel: f32,
    distance_traveled: f32,
    best_lap: f32,
    last_lap: f32,
    current_lap: f32,
    current_race_time: f32,
    lap_number: u16,
    race_position: u8,
    accel: u8,
    brake: u8,
    clutch: u8,
    handbrake: u8,
    gear: u8,
    steer: i8,
    normalized_driving_line: i8,
    normalized_ai_brake_difference: i8,
};
