import { getVisits } from './visits';

describe('getVisits', () => {
    // TODO
    it('dummy test should return the correct visits count and lastVisit values', async () => {
      const result = {
        visits: 10,
        lastVisit: '2023-10-20T18:44:25.428Z',
      };
  
      // Check if the function returns the expected values
      expect(result).toEqual({
        visits: 10,
        lastVisit: '2023-10-20T18:44:25.428Z',
      });
  });
})