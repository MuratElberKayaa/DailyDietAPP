using Microsoft.OpenApi.Models;
using Swashbuckle.AspNetCore.SwaggerGen;

namespace DailyDietAPI.Filters
{
    public class SwaggerResponseFilter : IDocumentFilter
    {
        public void Apply(OpenApiDocument swaggerDoc, DocumentFilterContext context)
        {
            foreach (var path in swaggerDoc.Paths.Values)
            {
                foreach (var operation in path.Operations.Values)
                {
                    // Sadece 200 OK response'larını tut
                    var responses = operation.Responses
                        .Where(r => r.Key == "200")
                        .ToDictionary(r => r.Key, r => r.Value);

                    operation.Responses.Clear();
                    foreach (var response in responses)
                    {
                        operation.Responses.Add(response.Key, response.Value);
                    }
                }
            }
        }
    }
} 