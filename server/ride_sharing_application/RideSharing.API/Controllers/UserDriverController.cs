using System;
using System.Collections.Generic;
using System.Threading.Tasks;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using RideSharing.API.Models.DTO;
using RideSharing.API.Repositories.Interface;

namespace RideSharing.API.Controllers
{
    [ApiController]
    [Route("api")]
    public class UserDriverController : ControllerBase
    {
        private readonly IUserDriverRepository _repo;

        public UserDriverController(IUserDriverRepository repo)
        {
            _repo = repo;
        }

        // GET /users/{id}
        [HttpGet("users/{id:guid}")]
        [Authorize]
        public async Task<ActionResult<UserProfileDto>> GetUserProfile(Guid id)
        {
            var dto = await _repo.GetUserProfileAsync(id);
            if (dto == null) return NotFound();
            return Ok(dto);
        }

        // PUT /users/{id}
        [HttpPut("users/{id:guid}")]
        [Authorize]
        public async Task<ActionResult<UserProfileDto>> UpdateUserProfile(Guid id, [FromBody] UpdateProfileRequest req)
        {
            var dto = await _repo.UpdateUserProfileAsync(id, req);
            if (dto == null) return NotFound();
            return Ok(dto);
        }

        // POST /drivers
        [HttpPost("drivers")]
        [Authorize]
        public async Task<ActionResult<DriverDto>> RegisterDriver([FromBody] DriverOnboardRequest req)
        {
            var dto = await _repo.RegisterDriverAsync(req);
            if (dto == null) return BadRequest("User not found");
            return CreatedAtAction(nameof(GetDriver), new { id = dto.Id }, dto);
        }

        // GET /drivers/{id}
        [HttpGet("drivers/{id:guid}")]
        [Authorize]
        public async Task<ActionResult<DriverDto>> GetDriver(Guid id)
        {
            throw new Exception("Simulated exception for testing global error handling.");
            var dto = await _repo.GetDriverAsync(id);
            if (dto == null) return NotFound();
            return Ok(dto);
        }

        // GET /drivers/{id}/routes
        [HttpGet("drivers/{id:guid}/routes")]
        [Authorize]
        public async Task<ActionResult<IEnumerable<RouteDto>>> GetDriverRoutes(Guid id)
        {
            var dtos = await _repo.GetDriverRoutesAsync(id);
            if (dtos == null) return NotFound();
            return Ok(dtos);
        }
    }
}