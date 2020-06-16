import algoliasearch from 'algoliasearch';
import instantsearch from 'instantsearch.js';

import { convertMilesToMetres } from '../lib/utils';
import { getFilters, getQuery } from './query';

// This is the public API key which can be safely used in your frontend code.
// This key is usable for search queries and list the indices you've got access to.
export const search = algoliasearch('QM2YE0HRBW', '4082ba44346a92023eac1f794d739dd1');

export const searchClient = indexName => instantsearch({
    indexName: indexName,
    searchClient: search,
    searchFunction(helper) {
        if (document.querySelector('#location').dataset.coordinates) {
            helper.state.aroundLatLng = document.querySelector('#location').dataset.coordinates;
        }

        if (document.querySelector('#radius').dataset.radius) {
            helper.state.aroundRadius = convertMilesToMetres(document.querySelector('#radius').dataset.radius);
            helper.state.query = document.querySelector('#keyword').value;
        } else {
            delete helper.state.aroundRadius;
            delete helper.state.aroundLatLng;
            helper.state.query = getQuery();
        }

        helper.state.filters = getFilters();

        helper.search();
    },
});

export const index = indexName => search.initIndex(indexName);
