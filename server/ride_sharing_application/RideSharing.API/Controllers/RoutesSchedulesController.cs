using Microsoft.AspNetCore.Mvc;
using RideSharing.API.Models.DTO;
using RideSharing.API.Repositories.Interface;
using AutoMapper;
using RideSharing.API.CustomValidations;

namespace RideSharing.API.Controllers
{
    [ApiController]
    [Route("api/routes")]
    public class RoutesSchedulesController : ControllerBase
    {
        private readonly IRoutesSchedulesRepository _repo;
        private readonly IMapper _mapper;

        public RoutesSchedulesController(IRoutesSchedulesRepository repo, IMapper mapper)
        {
            _repo = repo;
            _mapper = mapper;
        }

        // POST /routes
        [HttpPost]
        [ValidateModel]
        public async Task<ActionResult<RouteDto>> CreateRoute([FromBody] CreateRouteRequest req)
        {
            var dto = await _repo.CreateRouteAsync(req);
            if (dto == null) return BadRequest("Driver not found");
            return CreatedAtAction(nameof(GetRoute), new { id = dto.Id }, dto);
        }

        // GET /routes/{id}
        [HttpGet("{id:guid}")]
        [ValidateModel]
        public async Task<ActionResult<RouteDto>> GetRoute(Guid id)
        {
            var dto = await _repo.GetRouteAsync(id);
            if (dto == null) return NotFound();
            return Ok(dto);
        }

        // GET /routes?origin&destination
        [HttpGet]
        public async Task<ActionResult<IEnumerable<RouteDto>>> SearchRoutes([FromQuery] string origin, [FromQuery] string destination)
        {
            var dtos = await _repo.SearchRoutesAsync(origin, destination);
            return Ok(dtos);
        }

        // POST /routes/{id}/schedule-templates
        [HttpPost("{id:guid}/schedule-templates")]
        public async Task<ActionResult<ScheduleTemplateDto>> CreateScheduleTemplate(Guid id, [FromBody] CreateScheduleTemplateRequest req)
        {
            var dto = await _repo.CreateScheduleTemplateAsync(id, req);
            if (dto == null) return BadRequest("Route not found or RouteId mismatch");
            return CreatedAtAction(nameof(GetScheduleTemplates), new { id = dto.RouteId }, dto);
        }

        // GET /routes/{id}/schedule-templates
        [HttpGet("{id:guid}/schedule-templates")]
        public async Task<ActionResult<IEnumerable<ScheduleTemplateDto>>> GetScheduleTemplates(Guid id)
        {
            var dtos = await _repo.GetScheduleTemplatesAsync(id);
            return Ok(dtos);
        }

    }
}
