using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using RideSharing.API.Models.DTO;

namespace RideSharing.API.Repositories.Interface
{
    public interface IRoutesSchedulesRepository
    {
        Task<RouteDto?> CreateRouteAsync(CreateRouteRequest req);
        Task<RouteDto?> GetRouteAsync(Guid id);
        Task<IEnumerable<RouteDto>> SearchRoutesAsync(string origin, string destination);
        Task<ScheduleTemplateDto?> CreateScheduleTemplateAsync(Guid routeId, CreateScheduleTemplateRequest req);
        Task<IEnumerable<ScheduleTemplateDto>> GetScheduleTemplatesAsync(Guid routeId);
    }
}