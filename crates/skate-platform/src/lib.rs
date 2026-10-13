//! Platform abstraction: detached process spawning, helper executable naming
//! and crash reporting. Windows keeps the original creation-flags behavior;
//! other platforms use no-ops.
pub mod crash;
pub mod exe;
pub mod process;
